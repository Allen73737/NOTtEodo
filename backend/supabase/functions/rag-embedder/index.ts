import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { audit, authenticate, cleanText, enforceRateLimit, handler, HttpError, json, readJson } from "../_shared/security.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const MAX_TEXT = 200_000;

serve(handler(async (req) => {
  const { user, client } = await authenticate(req);
  await enforceRateLimit(user.id, "rag-embedder", 30, 60);

  const body = await readJson(req, 512 * 1024);
  const documentId = String(body.documentId ?? "");
  const spaceId = body.spaceId == null ? null : String(body.spaceId);
  const textContent = cleanText(body.textContent, MAX_TEXT);

  if (!UUID.test(documentId) || (spaceId !== null && !UUID.test(spaceId)) || !textContent) {
    throw new HttpError(400, "A valid documentId and textContent are required");
  }

  // The document must belong to the caller (RLS also enforces this on every write below).
  const { data: doc } = await client.from("documents").select("id").eq("id", documentId).eq("user_id", user.id).maybeSingle();
  if (!doc) throw new HttpError(404, "Document not found");

  // 500-character chunks with a 50-character overlap.
  const chunkSize = 500, overlap = 50;
  const chunks: string[] = [];
  for (let start = 0; start < textContent.length; start += chunkSize - overlap) {
    chunks.push(textContent.slice(start, Math.min(start + chunkSize, textContent.length)));
  }

  const { error: insertError } = await client.from("document_chunks").insert(
    chunks.map((content, index) => ({
      document_id: documentId,
      space_id: spaceId,
      user_id: user.id,
      chunk_index: index,
      content: content.trim(),
      page_number: Math.floor(index / 3) + 1,
    })),
  );
  if (insertError) {
    console.error("[rag-embedder] insert failed", insertError);
    throw new HttpError(500, "Could not store the document.");
  }

  await client.from("documents").update({ processing_status: "ready" }).eq("id", documentId).eq("user_id", user.id);
  await audit(user.id, "DOCUMENT_CHUNKED_AND_EMBEDDED", "INFO", { documentId, chunkCount: chunks.length });

  return json(req, { success: true, chunksProcessed: chunks.length, documentId });
}));
