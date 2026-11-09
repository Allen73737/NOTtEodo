import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { adminClient, audit, authenticate, enforceRateLimit, handler, HttpError, json, readJson } from "../_shared/security.ts";

// Permanently deletes the caller's account and everything stored for it:
// synced collections, keys, AI usage and audit rows (all cascade from auth.users),
// feedback (which would otherwise keep the email address), and uploaded photos and
// voice notes in Cloudinary. Required by Google Play and by privacy law (GDPR art. 17).
//
// The caller must send {"confirm": "DELETE"}; the app asks the user to type it.

const CLOUD_NAME = Deno.env.get("CLOUDINARY_CLOUD_NAME");
const API_KEY = Deno.env.get("CLOUDINARY_API_KEY");
const API_SECRET = Deno.env.get("CLOUDINARY_API_SECRET");

/** Deletes every Cloudinary asset under users/<id>/ for one resource type. Best effort. */
async function deleteMedia(userId: string, resourceType: "image" | "video"): Promise<void> {
  if (!CLOUD_NAME || !API_KEY || !API_SECRET) return;
  const auth = "Basic " + btoa(`${API_KEY}:${API_SECRET}`);
  const prefix = encodeURIComponent(`users/${userId}/`);
  // Cloudinary deletes up to 1000 assets per call; loop until none remain.
  for (let i = 0; i < 20; i++) {
    const res = await fetch(
      `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/resources/${resourceType}/upload?prefix=${prefix}`,
      { method: "DELETE", headers: { Authorization: auth } },
    );
    if (!res.ok) return;
    const body = await res.json().catch(() => ({}));
    if (!body.partial) return;
  }
}

serve(handler(async (req) => {
  const { user } = await authenticate(req);
  await enforceRateLimit(user.id, "delete-account", 3, 3600);

  const body = await readJson(req, 1024);
  if (body.confirm !== "DELETE") throw new HttpError(400, "Type DELETE to confirm.", "CONFIRMATION_REQUIRED");

  await audit(user.id, "ACCOUNT_DELETION_REQUESTED", "WARNING", { at: new Date().toISOString() });

  const admin = adminClient();
  await admin.from("user_feedback").delete().eq("user_id", user.id);
  await Promise.all([deleteMedia(user.id, "image"), deleteMedia(user.id, "video")]);

  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) throw new HttpError(500, "Could not delete the account. Please try again.", "DELETE_FAILED");

  return json(req, { deleted: true });
}));
