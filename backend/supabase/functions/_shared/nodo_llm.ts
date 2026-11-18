// The model behind Nodo. Provider, key and model order are server secrets; nothing
// here is ever returned to the client.
import { HttpError } from "./security.ts";

export const PROVIDER = "https://api.groq.com/openai/v1";
export const MODELS = (Deno.env.get("AI_MODELS") ?? "llama-3.3-70b-versatile,openai/gpt-oss-120b,llama-3.1-8b-instant")
  .split(",").map((m) => m.trim()).filter(Boolean);
export const FAST_MODEL = Deno.env.get("AI_FAST_MODEL") ?? "llama-3.1-8b-instant";

export type ChatMessage = { role: "system" | "user" | "assistant"; content: string };
export type ChatResult = { content: string; model: string; tier: number; tokens: number };

export function providerKey(): string {
  const key = Deno.env.get("GROQ_API_KEY");
  if (!key) throw new HttpError(503, "Nodo is not set up on this server yet.", "AI_NOT_CONFIGURED");
  return key;
}

/** Tries each model in turn until one answers. */
export async function chat(
  messages: ChatMessage[],
  opts: { userId: string; models?: string[]; maxTokens?: number; json?: boolean; temperature?: number; timeoutMs?: number },
): Promise<ChatResult> {
  const key = providerKey();
  const models = opts.models ?? MODELS;
  let lastStatus = 0;
  for (let i = 0; i < models.length; i++) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), opts.timeoutMs ?? 15_000);
    try {
      const res = await fetch(`${PROVIDER}/chat/completions`, {
        method: "POST",
        signal: controller.signal,
        headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          model: models[i],
          messages,
          temperature: opts.temperature ?? 0.4,
          max_tokens: opts.maxTokens ?? 900,
          user: opts.userId,
          ...(opts.json ? { response_format: { type: "json_object" } } : {}),
        }),
      });
      lastStatus = res.status;
      if (!res.ok) continue; // rate-limited or model unavailable: try the next one
      const data = await res.json();
      const content = String(data.choices?.[0]?.message?.content ?? "").trim();
      if (!content) continue;
      return { content, model: models[i], tier: i + 1, tokens: Number(data.usage?.total_tokens ?? 0) };
    } catch (_) {
      // timeout / network: next model
    } finally {
      clearTimeout(timer);
    }
  }
  throw new HttpError(lastStatus === 429 ? 429 : 502, "Nodo is busy right now. Please try again shortly.", "AI_UNAVAILABLE");
}

/** Runs [work] after the response is sent where the runtime allows it, else waits. */
export async function later(work: Promise<unknown>) {
  const rt = (globalThis as any).EdgeRuntime;
  const safe = work.catch((e) => console.error("[nodo] background work failed", e));
  if (rt?.waitUntil) rt.waitUntil(safe);
  else await safe;
}
