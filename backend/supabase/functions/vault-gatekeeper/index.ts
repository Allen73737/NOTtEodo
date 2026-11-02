import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { audit, authenticate, enforceRateLimit, handler, HttpError, json, readJson } from "../_shared/security.ts";

// Records vault-unlock events in the immutable audit trail. The vault itself is
// zero-knowledge: PINs and keys never reach the server, so there is nothing to verify here.
serve(handler(async (req) => {
  const { user } = await authenticate(req);
  try {
    await enforceRateLimit(user.id, "vault-auth", 5, 60);
  } catch (err) {
    await audit(user.id, "VAULT_BRUTE_FORCE_THROTTLED", "CRITICAL", { at: new Date().toISOString() });
    throw err;
  }

  const body = await readJson(req, 2 * 1024);
  if (body.action !== "VERIFY_CHALLENGE") throw new HttpError(400, "Unsupported action");

  await audit(user.id, "VAULT_ACCESSED_SUCCESSFULLY", "INFO", { at: new Date().toISOString() });
  return json(req, { success: true });
}));
