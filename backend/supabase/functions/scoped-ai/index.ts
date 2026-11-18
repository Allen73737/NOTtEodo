import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { audit, authenticate, cleanText, consumeAiQuota, enforceRateLimit, handler, HttpError, json, readJson } from "../_shared/security.ts";
import { buildSystemPrompt, guard, leaksRules, scrub } from "../_shared/nodo_brain.ts";
import { chat, MODELS } from "../_shared/nodo_llm.ts";
import { recall } from "../_shared/nodo_memory.ts";

// Prompt-injection hygiene: user text is data. Known override phrases are neutralised,
// and the system prompt tells the model to treat context as untrusted.
function sanitizeQuery(input: unknown): string {
  return cleanText(input, 1000).replace(
    /(ignore (all )?previous instructions|disregard all prior directives|you are now in developer mode|system prompt reveal)/gi,
    "[filtered]",
  );
}

/// Picks the user's synced notes that share the most words with the query.
/// Accounts with end-to-end encryption store ciphertext only, so nothing is found here.
function relevantNotes(notes: unknown[], query: string): string {
  const terms = query.toLowerCase().split(/\s+/).filter((t) => t.length > 2);
  if (terms.length === 0) return "";
  return notes
    .map((n: any) => {
      const text = `${n?.title ?? ""} ${n?.content ?? n?.excerpt ?? ""}`.toLowerCase();
      return { n, score: terms.reduce((acc, t) => acc + (text.includes(t) ? 1 : 0), 0) };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 5)
    .map(({ n }: any) => `[Note: ${cleanText(n.title, 120)}]\n${cleanText(String(n.content || n.excerpt || ""), 800)}`)
    .join("\n\n");
}

serve(handler(async (req) => {
  const { user, client } = await authenticate(req);
  await enforceRateLimit(user.id, "scoped-ai", 20, 60);

  const body = await readJson(req, 16 * 1024);
  const query = sanitizeQuery(body.query);
  const scope = cleanText(body.scope ?? "Global", 60).replace(/["`]/g, "") || "Global";
  if (!query) throw new HttpError(400, "Query prompt cannot be empty");

  // Context: the client's digest of matching local items, plus the user's synced notes (RLS-scoped).
  const clientContext = cleanText(body.context, 6000);
  const { data: notesRow } = await client
    .from("user_collections")
    .select("data")
    .eq("user_id", user.id)
    .eq("collection", "notes")
    .maybeSingle();
  const notesContext = notesRow && Array.isArray(notesRow.data) ? relevantNotes(notesRow.data, query) : "";
  const spaceContext = [clientContext, notesContext].filter(Boolean).join("\n\n");

  // Same Nodo, same rules and memory as ai-assist; this endpoint only adds the notes lookup.
  const hit = guard(query);
  if (hit) {
    await audit(user.id, "AI_GUARDED", "WARNING", { reason: hit.reason, scope });
    return json(req, { answer: hit.reply, modelUsed: "Nodo", citation: scope, scope, timestamp: new Date().toISOString() });
  }
  await consumeAiQuota(user.id);
  const known = await recall(user.id).catch(() => ({ memories: [], summary: "" }));
  const system = buildSystemPrompt({ mode: "nodo", query, scope, memories: known.memories, summary: known.summary, context: spaceContext });

  let answer = "";
  try {
    const result = await chat([{ role: "system", content: system }, { role: "user", content: query }], { userId: user.id, maxTokens: 1000 });
    answer = scrub(result.content, MODELS);
    if (leaksRules(answer)) answer = "I'd rather keep my inner workings to myself. What can I help you with?";
  } catch (_) {
    // Nodo is unreachable: hand back the matching items themselves.
    answer = spaceContext
      ? `Here are the most relevant items from your space for "${query}":

${spaceContext}`
      : `Nothing in your "${scope}" space matches "${query}" yet.`;
  }

  await audit(user.id, "AI_QUERY_PROCESSED", "INFO", { scope, query_length: query.length });

  return json(req, {
    answer,
    modelUsed: "Nodo",
    citation: scope,
    scope,
    timestamp: new Date().toISOString(),
  });
}));
