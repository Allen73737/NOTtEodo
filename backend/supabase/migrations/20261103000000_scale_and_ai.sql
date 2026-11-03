-- ============================================================================
-- NOTtEodo: Scale & AI
-- Migration: 20261103000000_scale_and_ai.sql
--
-- Sized for hundreds of concurrent users on a small Supabase instance:
-- 1. RLS predicates evaluate auth.uid() once per statement, not once per row.
-- 2. Every user-scoped table has an index leading with user_id.
-- 3. Hot paths (delta sync, audit throttling, rate limiting) are index-only.
-- 4. Rate-limit pruning leaves the request path; retention runs in pg_cron.
-- 5. A per-user daily AI allowance (ai_usage + consume_ai_quota).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. RLS performance: wrap auth.uid() / mfa_satisfied() in a sub-select (initPlan)
--    https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    p RECORD;
    v_using TEXT;
    v_check TEXT;
    v_sql TEXT;
BEGIN
    FOR p IN
        SELECT schemaname, tablename, policyname, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        v_using := p.qual;
        v_check := p.with_check;
        IF v_using IS NOT NULL AND v_using NOT LIKE '%SELECT auth.uid()%' THEN
            v_using := replace(v_using, 'auth.uid()', '(SELECT auth.uid())');
        END IF;
        IF v_check IS NOT NULL AND v_check NOT LIKE '%SELECT auth.uid()%' THEN
            v_check := replace(v_check, 'auth.uid()', '(SELECT auth.uid())');
        END IF;
        IF v_using IS NOT NULL AND v_using NOT LIKE '%SELECT %mfa_satisfied()%' THEN
            v_using := regexp_replace(v_using, '(public\.)?mfa_satisfied\(\)', '(SELECT public.mfa_satisfied())', 'g');
        END IF;
        IF v_check IS NOT NULL AND v_check NOT LIKE '%SELECT %mfa_satisfied()%' THEN
            v_check := regexp_replace(v_check, '(public\.)?mfa_satisfied\(\)', '(SELECT public.mfa_satisfied())', 'g');
        END IF;

        IF v_using IS DISTINCT FROM p.qual OR v_check IS DISTINCT FROM p.with_check THEN
            v_sql := format('ALTER POLICY %I ON %I.%I', p.policyname, p.schemaname, p.tablename);
            IF v_using IS NOT NULL THEN v_sql := v_sql || format(' USING (%s)', v_using); END IF;
            IF v_check IS NOT NULL THEN v_sql := v_sql || format(' WITH CHECK (%s)', v_check); END IF;
            EXECUTE v_sql;
        END IF;
    END LOOP;
END
$$;

-- ----------------------------------------------------------------------------
-- 2. Index every public table's user_id (RLS filters on it in every query)
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT c.table_name
        FROM information_schema.columns c
        JOIN information_schema.tables tb
          ON tb.table_schema = c.table_schema AND tb.table_name = c.table_name AND tb.table_type = 'BASE TABLE'
        WHERE c.table_schema = 'public' AND c.column_name = 'user_id'
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM pg_index i
            JOIN pg_class tc ON tc.oid = i.indrelid
            JOIN pg_namespace n ON n.oid = tc.relnamespace
            JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = i.indkey[0]
            WHERE n.nspname = 'public' AND tc.relname = t.table_name AND a.attname = 'user_id'
        ) THEN
            EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON public.%I (user_id)', 'idx_' || t.table_name || '_user_id', t.table_name);
        END IF;
    END LOOP;
END
$$;

-- Delta sync: "rows changed since my last sync" is an index range scan.
CREATE INDEX IF NOT EXISTS idx_user_collections_user_updated ON public.user_collections (user_id, updated_at);

-- log_security_event throttles per user per minute; this keeps it index-only.
CREATE INDEX IF NOT EXISTS idx_security_audit_user_time ON public.security_audit_logs (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_audit_time ON public.security_audit_logs (created_at);

-- Pruning old rate-limit rows by time.
CREATE INDEX IF NOT EXISTS idx_rate_limit_time ON public.rate_limit_records (request_timestamp);

-- High-churn tables: vacuum earlier, leave room for HOT updates.
ALTER TABLE public.rate_limit_records SET (autovacuum_vacuum_scale_factor = 0.02, autovacuum_analyze_scale_factor = 0.02);
ALTER TABLE public.user_collections SET (fillfactor = 85, autovacuum_vacuum_scale_factor = 0.05);

-- ----------------------------------------------------------------------------
-- 3. Rate limiting without a table-wide DELETE on every request
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_rate_limit(
    p_user_id UUID,
    p_endpoint TEXT,
    p_max_requests INT DEFAULT 60,
    p_window_seconds INT DEFAULT 60
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_recent_count INT;
BEGIN
    IF auth.uid() IS NOT NULL AND p_user_id IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'rate limit subject must be the caller' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF p_user_id IS NULL OR p_endpoint !~ '^[a-z0-9_-]{1,64}$'
       OR p_max_requests NOT BETWEEN 1 AND 10000 OR p_window_seconds NOT BETWEEN 1 AND 86400 THEN
        RAISE EXCEPTION 'invalid rate limit arguments' USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Without pg_cron, about 1 request in 200 tidies up (bounded by the time index).
    IF random() < 0.005 AND NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        DELETE FROM public.rate_limit_records WHERE request_timestamp < NOW() - INTERVAL '1 day';
    END IF;

    SELECT COUNT(*) INTO v_recent_count
    FROM public.rate_limit_records
    WHERE user_id = p_user_id
      AND endpoint = p_endpoint
      AND request_timestamp >= NOW() - make_interval(secs => p_window_seconds);

    IF v_recent_count >= p_max_requests THEN
        INSERT INTO public.security_audit_logs (user_id, event_type, severity, metadata)
        VALUES (p_user_id, 'RATE_LIMIT_EXCEEDED', 'WARNING',
                jsonb_build_object('endpoint', p_endpoint, 'limit', p_max_requests, 'window_seconds', p_window_seconds));
        RETURN FALSE;
    END IF;

    INSERT INTO public.rate_limit_records (user_id, endpoint, request_timestamp) VALUES (p_user_id, p_endpoint, NOW());
    RETURN TRUE;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.check_rate_limit(UUID, TEXT, INT, INT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_rate_limit(UUID, TEXT, INT, INT) TO service_role;

-- ----------------------------------------------------------------------------
-- 4. Daily AI allowance
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_usage (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day DATE NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')::date,
    requests INT NOT NULL DEFAULT 0 CHECK (requests >= 0),
    PRIMARY KEY (user_id, day)
);
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ai_usage_select_own" ON public.ai_usage;
CREATE POLICY "ai_usage_select_own" ON public.ai_usage
    FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
REVOKE ALL ON public.ai_usage FROM anon;
REVOKE INSERT, UPDATE, DELETE ON public.ai_usage FROM authenticated;

-- Atomically counts one request; FALSE once today's limit is reached. One row
-- per user per day, so this is a single-row upsert even under heavy load.
CREATE OR REPLACE FUNCTION public.consume_ai_quota(p_user_id UUID, p_limit INT DEFAULT 200)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_requests INT;
BEGIN
    IF p_user_id IS NULL OR p_limit NOT BETWEEN 1 AND 100000 THEN
        RAISE EXCEPTION 'invalid quota arguments' USING ERRCODE = 'invalid_parameter_value';
    END IF;
    INSERT INTO public.ai_usage AS u (user_id, day, requests)
    VALUES (p_user_id, (NOW() AT TIME ZONE 'utc')::date, 1)
    ON CONFLICT (user_id, day) DO UPDATE SET requests = u.requests + 1
        WHERE u.requests < p_limit
    RETURNING requests INTO v_requests;
    RETURN v_requests IS NOT NULL;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.consume_ai_quota(UUID, INT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.consume_ai_quota(UUID, INT) TO service_role;

-- ----------------------------------------------------------------------------
-- 5. Retention jobs (Supabase ships pg_cron; skipped silently elsewhere)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pg_cron') THEN
        CREATE EXTENSION IF NOT EXISTS pg_cron;
        PERFORM cron.unschedule(jobid) FROM cron.job
         WHERE jobname IN ('nt_prune_rate_limits', 'nt_prune_ai_usage', 'nt_prune_audit_logs');
        PERFORM cron.schedule('nt_prune_rate_limits', '*/15 * * * *',
            $job$DELETE FROM public.rate_limit_records WHERE request_timestamp < NOW() - INTERVAL '1 day'$job$);
        PERFORM cron.schedule('nt_prune_ai_usage', '17 3 * * *',
            $job$DELETE FROM public.ai_usage WHERE day < (NOW() AT TIME ZONE 'utc')::date - 35$job$);
        PERFORM cron.schedule('nt_prune_audit_logs', '41 3 * * 0',
            $job$DELETE FROM public.security_audit_logs WHERE created_at < NOW() - INTERVAL '365 days'$job$);
    END IF;
EXCEPTION WHEN insufficient_privilege OR undefined_function THEN
    RAISE NOTICE 'pg_cron not available; pruning falls back to the request path.';
END
$$;
