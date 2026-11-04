import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  authenticate,
  cleanText,
  enforceRateLimit,
  handler,
  HttpError,
  json,
  readJson,
} from "../_shared/security.ts";

// Secure Cloudinary Gateway for NOTtEodo.
// 1. Enforces Supabase User JWT authentication.
// 2. Sandboxes uploads to `users/${user.id}/${category}`.
// 3. Injects automatic EXIF/GPS location stripping (`fl_strip_profile`).
// 4. Keeps the Cloudinary API Secret securely on the server.

const CLOUD_NAME = Deno.env.get("CLOUDINARY_CLOUD_NAME");
const API_KEY = Deno.env.get("CLOUDINARY_API_KEY");
const API_SECRET = Deno.env.get("CLOUDINARY_API_SECRET");

async function sha1Hex(message: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hash = await crypto.subtle.digest("SHA-1", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function buildSignatureString(params: Record<string, string | number>): string {
  const sortedKeys = Object.keys(params).sort();
  const pairs = sortedKeys
    .filter((k) => params[k] !== undefined && params[k] !== null && params[k] !== "")
    .map((k) => `${k}=${params[k]}`);
  return pairs.join("&");
}

serve(handler(async (req) => {
  const { user } = await authenticate(req);
  await enforceRateLimit(user.id, "cloudinary-sign", 60, 60);

  if (!CLOUD_NAME || !API_KEY || !API_SECRET) {
    throw new HttpError(503, "Cloudinary is not configured on this server.", "CLOUDINARY_NOT_CONFIGURED");
  }

  const body = await readJson(req, 64 * 1024);
  const task = String(body.task ?? "upload_signature");

  if (task === "upload_signature") {
    // Sanitize category (e.g. wardrobe, moodboard, notes, spaces, avatars)
    const rawCategory = cleanText(body.category ?? "media", 30).toLowerCase().replace(/[^a-z0-9_-]/g, "");
    const allowedCategories = ["wardrobe", "moodboard", "notes", "spaces", "avatars", "documents", "media"];
    const category = allowedCategories.includes(rawCategory) ? rawCategory : "media";

    // Strict user sandboxing: users can ONLY upload to their own folder path
    const folder = `users/${user.id}/${category}`;
    const timestamp = Math.floor(Date.now() / 1000);

    // Security transformation: strip sensitive camera/phone GPS metadata automatically
    const transformation = "fl_strip_profile,q_auto,f_auto";

    const paramsToSign: Record<string, string | number> = {
      folder,
      timestamp,
      transformation,
    };

    const signatureStr = buildSignatureString(paramsToSign) + API_SECRET;
    const signature = await sha1Hex(signatureStr);

    return json(req, {
      cloud_name: CLOUD_NAME,
      api_key: API_KEY,
      timestamp,
      folder,
      transformation,
      signature,
      upload_url: `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`,
      user_id: user.id,
    });
  }

  if (task === "sign_delivery") {
    // Generate secure delivery link for private assets
    const publicId = cleanText(body.public_id, 256);
    if (!publicId) throw new HttpError(400, "public_id is required");

    // Strict verification: User can only sign delivery for their own folder
    if (!publicId.startsWith(`users/${user.id}/`)) {
      throw new HttpError(403, "Access denied: Asset belongs to another user.");
    }

    const timestamp = Math.floor(Date.now() / 1000) + 3600; // valid for 1 hour
    const toSign = `public_id=${publicId}&timestamp=${timestamp}${API_SECRET}`;
    const signature = await sha1Hex(toSign);

    return json(req, {
      public_id: publicId,
      expires_at: timestamp,
      signature,
    });
  }

  throw new HttpError(400, "Unknown task");
}));
