// Shared hardening for every NOTtEodo edge function.
import { createClient, SupabaseClient, User } from "https://esm.sh/@supabase/supabase-js@2.39.8";

/** Comma-separated list of allowed web origins, e.g. "https://app.notteodo.com". */
const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

export class HttpError extends Error {
  constructor(public status: number, message: string, public code?: string) {
    super(message);
  }
}

/**
 * CORS: with ALLOWED_ORIGINS set, only those origins are echoed back. Without it,
 * any origin is allowed. That is still safe here: auth is a bearer token, never a
 * cookie, so a foreign page cannot ride on the user's session.
 */
export function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const allow = allowedOrigins.length === 0 ? "*" : allowedOrigins.includes(origin) ? origin : allowedOrigins[0];
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Max-Age": "600",
    "Vary": "Origin",
  };
}

const securityHeaders: Record<string, string> = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
  "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
  "Strict-Transport-Security": "max-age=63072000; includeSubDomains",
};

export function json(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders(req), ...securityHeaders } });
}

/** Rejects browsers' cross-origin calls from origins outside the allowlist. */
export function assertOrigin(req: Request) {
  const origin = req.headers.get("Origin");
  if (origin && allowedOrigins.length > 0 && !allowedOrigins.includes(origin)) {
    throw new HttpError(403, "Origin not allowed");
  }
}

/** Parses a JSON object body of at most [maxBytes]. */
export async function readJson(req: Request, maxBytes: number): Promise<Record<string, unknown>> {
  if (req.method !== "POST") throw new HttpError(405, "Method not allowed");
  const declared = Number(req.headers.get("Content-Length") ?? "0");
  if (declared > maxBytes) throw new HttpError(413, "Request too large");
  const text = await req.text();
  if (new TextEncoder().encode(text).length > maxBytes) throw new HttpError(413, "Request too large");
  try {
    const parsed = JSON.parse(text);
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error();
    return parsed as Record<string, unknown>;
  } catch {
    throw new HttpError(400, "Body must be a JSON object");
  }
}

/** The caller's user (verified with Supabase Auth) and an RLS-scoped client acting as them. */
export async function authenticate(req: Request): Promise<{ user: User; client: SupabaseClient }> {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!/^Bearer\s+[\w-]+\.[\w-]+\.[\w-]+$/.test(authHeader)) {
    throw new HttpError(401, "Missing or malformed authorization header");
  }
  const client = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw new HttpError(401, "Unauthorized");
  return { user: data.user, client };
}

let admin: SupabaseClient | null = null;
function adminClient(): SupabaseClient {
  admin ??= createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "", {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return admin;
}

/** Sliding-window limit per user and endpoint. Fails closed if the check itself errors. */
export async function enforceRateLimit(userId: string, endpoint: string, max: number, windowSeconds: number) {
  const { data, error } = await adminClient().rpc("check_rate_limit", {
    p_user_id: userId,
    p_endpoint: endpoint,
    p_max_requests: max,
    p_window_seconds: windowSeconds,
  });
  if (error || data !== true) {
    throw new HttpError(429, "Too many requests. Please pause for a moment and try again.", "RATE_LIMITED");
  }
}

/** Daily per-user AI allowance (AI_DAILY_REQUESTS, default 200). Fails closed. */
export async function consumeAiQuota(userId: string) {
  const limit = Number(Deno.env.get("AI_DAILY_REQUESTS") ?? "200");
  const { data, error } = await adminClient().rpc("consume_ai_quota", { p_user_id: userId, p_limit: limit });
  if (error || data !== true) {
    throw new HttpError(429, "You have used today's AI allowance. It resets at midnight UTC.", "QUOTA_EXCEEDED");
  }
}

/** Writes a server-side audit entry (may use CRITICAL). Never throws. */
export async function audit(userId: string, eventType: string, severity: "INFO" | "WARNING" | "CRITICAL", metadata = {}) {
  try {
    await adminClient().from("security_audit_logs").insert({ user_id: userId, event_type: eventType, severity, metadata });
  } catch (_) {
    // Auditing must never break the request.
  }
}

/** Strips control characters and caps length. */
export function cleanText(input: unknown, max: number): string {
  if (typeof input !== "string") return "";
  return input.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "").trim().slice(0, max);
}

/** Wraps a handler with CORS preflight, origin checks and safe error responses. */
export function handler(fn: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders(req) });
    try {
      assertOrigin(req);
      return await fn(req);
    } catch (err) {
      if (err instanceof HttpError) return json(req, { error: err.message, code: err.code }, err.status);
      // Log details server-side only; clients get a generic message.
      console.error("[edge] unhandled error", err);
      return json(req, { error: "An internal error occurred." }, 500);
    }
  };
}
