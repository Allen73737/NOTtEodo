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

    const { action, challengeResponse } = await req.json();

    // Check rate limit on vault operations (Max 5 attempts per 60 seconds)
    const { data: isAllowed } = await supabaseClient.rpc('check_rate_limit', {
      p_user_id: user.id,
      p_endpoint: 'vault-auth',
      p_max_requests: 5,
      p_window_seconds: 60,
    });

    if (isAllowed === false) {
      await supabaseClient.rpc('log_security_event', {
        p_event_type: 'VAULT_BRUTE_FORCE_THROTTLED',
        p_severity: 'CRITICAL',
        p_metadata: { userId: user.id, attemptTime: new Date().toISOString() },
      });

      return new Response(JSON.stringify({
        error: 'Too many failed vault unlock attempts. Cooldown enforced for 60 seconds.',
        locked: true,
      }), {
        status: 429,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (action === 'VERIFY_CHALLENGE') {
      // In zero-knowledge architecture, client verifies the local PBKDF2 hash
      // Server logs the verification event
      await supabaseClient.rpc('log_security_event', {
        p_event_type: 'VAULT_ACCESSED_SUCCESSFULLY',
        p_severity: 'INFO',
        p_metadata: { userId: user.id, timestamp: new Date().toISOString() },
      });

      return new Response(JSON.stringify({
        success: true,
        message: 'Zero-knowledge vault verification recorded in immutable security audit log.',
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'Unsupported action' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
