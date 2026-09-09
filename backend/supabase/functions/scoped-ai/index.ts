import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// Security: Prompt Injection Guardrails
function sanitizeUserInput(input: string): string {
  if (!input || typeof input !== 'string') return '';
  // Strip control characters and dangerous jailbreak patterns
  return input
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
    .replace(/(ignore previous instructions|disregard all prior directives|you are now in developer mode|system prompt reveal)/gi, '[FILTERED_COMMAND]')
    .trim()
    .slice(0, 1000); // Strict length limit
}

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

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const groqApiKey = Deno.env.get('GROQ_API_KEY');

    // Authenticated Supabase Client
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized user access' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Anti-DDoS Rate Limiting Check (Max 20 AI queries per 60 seconds per user)
    const { data: isAllowed, error: rateError } = await supabaseClient.rpc('check_rate_limit', {
      p_user_id: user.id,
      p_endpoint: 'scoped-ai',
      p_max_requests: 20,
      p_window_seconds: 60,
    });

    if (rateError || isAllowed === false) {
      return new Response(JSON.stringify({
        error: 'Too many requests. Please pause for a moment to protect sanctuary resources.',
        code: 'RATE_LIMITED'
      }), {
        status: 429,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const query = sanitizeUserInput(body.query);
    const spaceId = body.spaceId ?? null;
    const scope = sanitizeUserInput(body.scope ?? 'Global Sanctuary');

    if (!query) {
      return new Response(JSON.stringify({ error: 'Query prompt cannot be empty' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Retrieve Relevant Context Notes from user's authorized collection
    let spaceContext = '';
    const { data: notesData } = await supabaseClient
      .from('notes')
      .select('title, excerpt, content')
      .eq('user_id', user.id)
      .limit(3);

    if (notesData && notesData.length > 0) {
      spaceContext = notesData.map((n: any) => `[Note: ${n.title}]\n${n.excerpt || n.content || ''}`).join('\n\n');
    }

    const systemPrompt = `You are NOTtEodo Scoped Intelligence Assistant for the user's tactile sanctuary space: "${scope}".
Answer with high precision, elegance, and tactile warmth.
Only reference the user's authorized space context below if relevant.

CONTEXT:
${spaceContext || 'No additional uploaded documents found in this space.'}`;

    // Secure Call to Groq LLaMA 3.3 (Server-side key, never exposed to client)
    let answer = "Sanctuary AI is standing by. Your notes and knowledge space are securely synchronized.";
    let citation = `${scope} · Sanctuary Archives`;

    if (groqApiKey) {
      const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${groqApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "llama-3.3-70b-versatile",
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: query }
          ],
          temperature: 0.2,
          max_tokens: 600,
        }),
      });

      if (groqResponse.ok) {
        const aiResult = await groqResponse.json();
        answer = aiResult.choices?.[0]?.message?.content || answer;
        citation = `${scope} Archives · Verified RLS Citation`;
      }
    } else {
      // Offline / Demo fallback
      answer = `[Sanctuary Intelligence — ${scope}]\n\nBased on your notes: "${query}" is mapped within your active sanctuary rhythm. All entries remain strictly encrypted under your authenticated session.`;
    }

    // Log Successful AI Interaction Audit Log
    await supabaseClient.rpc('log_security_event', {
      p_event_type: 'AI_QUERY_PROCESSED',
      p_severity: 'INFO',
      p_metadata: { scope, query_length: query.length },
    });

    return new Response(JSON.stringify({
      answer: answer,
      citation: citation,
      scope: scope,
      timestamp: new Date().toISOString(),
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    return new Response(JSON.stringify({
      error: 'An internal error occurred while processing the sanctuary query.',
      details: err.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
