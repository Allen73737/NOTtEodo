// Nodo's memory store. Every read and write is keyed by the caller's verified user id;
// nothing here ever reads another account's rows.
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";
import { adminClient } from "./security.ts";
import { EXTRACTOR, Extraction, Insight, leaksRules, Memory, parseExtraction } from "./nodo_brain.ts";
import { chat, FAST_MODEL, MODELS } from "./nodo_llm.ts";

export type Recall = { memories: Memory[]; summary: string };

export async function recall(userId: string): Promise<Recall> {
  const db = adminClient();
  const [mem, thread] = await Promise.all([
    db.from("nodo_memories").select("id, kind, content").eq("user_id", userId).order("last_seen_at", { ascending: false }).limit(40),
    db.from("nodo_threads").select("summary").eq("user_id", userId).maybeSingle(),
  ]);
  return { memories: (mem.data ?? []) as Memory[], summary: String(thread.data?.summary ?? "") };
}

// Approved shared knowledge changes rarely; each function instance keeps it 5 minutes.
let insightCache: { at: number; rows: Insight[] } | null = null;

/** Approved common questions most relevant to [query]. Holds no personal data. */
export async function sharedInsights(query: string, limit = 6): Promise<Insight[]> {
  if (!insightCache || Date.now() - insightCache.at > 5 * 60_000) {
    const { data } = await adminClient().from("nodo_app_insights").select("topic, question, answer")
      .eq("status", "approved").not("answer", "is", null).order("hits", { ascending: false }).limit(80);
    insightCache = { at: Date.now(), rows: (data ?? []) as Insight[] };
  }
  const words = new Set(query.toLowerCase().split(/\W+/).filter((w) => w.length > 3));
  return insightCache.rows
    .map((i) => ({ i, score: i.question.toLowerCase().split(/\W+/).filter((w) => words.has(w)).length }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((x) => x.i);
}

/** Records an answer so it can be rated; returns its id. */
export async function openTurn(userId: string): Promise<string | null> {
  const db = adminClient();
  const { data } = await db.from("nodo_turns").insert({ user_id: userId }).select("id").single();
  // Without pg_cron, about 1 turn in 100 prunes the old ones.
  if (Math.random() < 0.01) await db.from("nodo_turns").delete().lt("created_at", new Date(Date.now() - 30 * 864e5).toISOString());
  return data?.id ?? null;
}

/** After a chat: learns new memories, updates the running summary, notes app questions. */
export async function learn(opts: {
  userId: string;
  turnId: string | null;
  known: Recall;
  question: string;
  answer: string;
}) {
  const { userId, turnId, known, question, answer } = opts;
  const result = await chat([
    { role: "system", content: EXTRACTOR },
    {
      role: "user",
      content: `KNOWN:\n${known.memories.map((m) => `- ${m.content}`).join("\n") || "- (none)"}\n\n` +
        `SUMMARY SO FAR:\n${known.summary || "(none)"}\n\nUSER:\n${question.slice(0, 2000)}\n\nNODO:\n${answer.slice(0, 2000)}`,
    },
  ], { userId, json: true, maxTokens: 500, temperature: 0.1, models: [FAST_MODEL, ...MODELS], timeoutMs: 12_000 });
  const x: Extraction = parseExtraction(result.content);
  const db = adminClient();

  // Forget first, so a corrected fact can be stored again below.
  const toForget = known.memories.filter((m) => x.forget.some((f) => m.content.toLowerCase().includes(f.toLowerCase())));
  if (toForget.length) await db.from("nodo_memories").delete().eq("user_id", userId).in("id", toForget.map((m) => m.id!));

  const seen = new Set(known.memories.filter((m) => !toForget.includes(m)).map((m) => m.content.toLowerCase()));
  const fresh = x.memories.filter((m) => !seen.has(m.content.toLowerCase()));
  for (const m of fresh) {
    // The unique index on (user_id, lower(content)) quietly rejects a duplicate.
    await db.from("nodo_memories").insert({ user_id: userId, kind: m.kind, content: m.content });
  }

  if (x.summary && !leaksRules(x.summary)) {
    await db.from("nodo_threads").upsert({ user_id: userId, summary: x.summary.slice(0, 2000), updated_at: new Date().toISOString() });
  }

  if (x.appQuestion) {
    await db.rpc("nodo_note_question", { p_topic: x.appQuestion.topic, p_question: x.appQuestion.question });
    if (turnId) {
      await db.from("nodo_turns").update({
        topic: x.appQuestion.topic,
        generic_question: x.appQuestion.question,
        generic_answer: x.appQuestion.answer || null,
      }).eq("id", turnId).eq("user_id", userId);
    }
  }
  return fresh.length;
}

/** A thumbs up or down on one of the caller's own answers. Each answer is rated once. */
export async function rate(userId: string, turnId: string, rating: 1 | -1): Promise<boolean> {
  const db = adminClient();
  const { data: turn } = await db.from("nodo_turns").select("id, topic, generic_answer, rating")
    .eq("id", turnId).eq("user_id", userId).maybeSingle();
  if (!turn || turn.rating != null) return false;
  await db.from("nodo_turns").update({ rating }).eq("id", turnId).eq("user_id", userId);
  if (turn.topic) {
    await db.rpc("nodo_rate_insight", { p_topic: turn.topic, p_rating: rating, p_answer: turn.generic_answer });
  }
  return true;
}

/** The caller's own memories, read through their RLS-scoped client. */
export async function listMemories(client: SupabaseClient, userId: string) {
  const { data } = await client.from("nodo_memories").select("id, kind, content, created_at")
    .eq("user_id", userId).order("created_at", { ascending: false }).limit(150);
  return data ?? [];
}

/** Deletes one memory, or all of them and the chat summary. */
export async function forget(client: SupabaseClient, userId: string, id: string | null) {
  if (id) {
    await client.from("nodo_memories").delete().eq("user_id", userId).eq("id", id);
  } else {
    await client.from("nodo_memories").delete().eq("user_id", userId);
    await client.from("nodo_threads").delete().eq("user_id", userId);
  }
}

/** Live, aggregate figures for Architect mode. Never includes private user content. */
export async function operationsBrief(): Promise<string> {
  const db = adminClient();
  const since = new Date(Date.now() - 864e5).toISOString();
  const today = new Date().toISOString().slice(0, 10);
  const lines: string[] = [];
  const safe = async (label: string, fn: () => Promise<string>) => {
    try {
      lines.push(`${label}: ${await fn()}`);
    } catch (_) {
      lines.push(`${label}: unavailable`);
    }
  };
  await Promise.all([
    safe("Admins", async () => String((await db.from("app_admins").select("*", { count: "exact", head: true })).count ?? 0)),
    safe("Accounts using AI today", async () => {
      const { data } = await db.from("ai_usage").select("requests").eq("day", today).limit(5000);
      const rows = data ?? [];
      return `${rows.length} (${rows.reduce((a: number, r: any) => a + Number(r.requests ?? 0), 0)} requests)`;
    }),
    safe("Feedback", async () => {
      const { data } = await db.from("user_feedback").select("title, status, created_at").order("created_at", { ascending: false }).limit(60);
      const rows = data ?? [];
      const pending = rows.filter((r: any) => r.status === "pending");
      return `${pending.length} pending of the latest ${rows.length}. Latest pending titles: ` +
        (pending.slice(0, 8).map((r: any) => `"${String(r.title).slice(0, 80)}"`).join("; ") || "none");
    }),
    safe("Security events (24 h)", async () => {
      const { data } = await db.from("security_audit_logs").select("event_type, severity").gte("created_at", since).limit(2000);
      const rows = data ?? [];
      const by: Record<string, number> = {};
      for (const r of rows as any[]) if (r.severity !== "INFO") by[`${r.severity} ${r.event_type}`] = (by[`${r.severity} ${r.event_type}`] ?? 0) + 1;
      const top = Object.entries(by).sort((a, b) => b[1] - a[1]).slice(0, 8).map(([k, v]) => `${k} ×${v}`).join(", ");
      return `${rows.length} total; non-info: ${top || "none"}`;
    }),
    safe("Nodo learning", async () => {
      const { data } = await db.from("nodo_app_insights").select("topic, question, hits, score, status").order("hits", { ascending: false }).limit(40);
      const rows = (data ?? []) as any[];
      const cand = rows.filter((r) => r.status === "candidate").slice(0, 10)
        .map((r) => `${r.topic} ("${r.question}", ${r.hits} asks, score ${r.score})`).join("; ");
      return `${rows.filter((r) => r.status === "approved").length} approved; top candidates: ${cand || "none"}`;
    }),
  ]);
  return lines.join("\n");
}
