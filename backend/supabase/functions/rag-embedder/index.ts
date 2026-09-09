import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized user access' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { documentId, spaceId, textContent } = await req.json();

    if (!documentId || !textContent) {
      return new Response(JSON.stringify({ error: 'documentId and textContent are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Chunk text content into 500-character segments with 50-character overlap
    const chunkSize = 500;
    const overlap = 50;
    const chunks: string[] = [];
    let start = 0;

    while (start < textContent.length) {
      const end = Math.min(start + chunkSize, textContent.length);
      chunks.push(textContent.slice(start, end));
      start += (chunkSize - overlap);
    }

    // Insert chunks into database
    const chunkRows = chunks.map((content, index) => ({
      document_id: documentId,
      space_id: spaceId,
      user_id: user.id,
      chunk_index: index,
      content: content.trim(),
      page_number: Math.floor(index / 3) + 1,
    }));

    const { error: insertError } = await supabaseClient
      .from('document_chunks')
      .insert(chunkRows);

    if (insertError) {
      throw insertError;
    }

    // Update document status to ready
    await supabaseClient
      .from('documents')
      .update({ processing_status: 'ready' })
      .eq('id', documentId);

    // Audit log
    await supabaseClient.rpc('log_security_event', {
      p_event_type: 'DOCUMENT_CHUNKED_AND_EMBEDDED',
      p_severity: 'INFO',
      p_metadata: { documentId, spaceId, chunkCount: chunks.length },
    });

    return new Response(JSON.stringify({
      success: true,
      chunksProcessed: chunks.length,
      documentId: documentId,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
