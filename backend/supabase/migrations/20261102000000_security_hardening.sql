-- ============================================================================
-- NOTtEodo Security Hardening
-- Migration: 20261102000000_security_hardening.sql
--
-- 1. user_keys: end-to-end encryption key records (only a passphrase-wrapped key).
-- 2. user_collections accepts encrypted envelopes, and refuses plaintext once an
--    account has turned on end-to-end encryption.
-- 3. Accounts with two-step verification need an AAL2 session to touch their data.
-- 4. SECURITY DEFINER functions: fixed search_path, caller-bound rate limiting,
--    validated audit events, and no access for the anon role.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. End-to-end encryption key records
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_keys (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    -- {"alg":"pbkdf2-hmac-sha256","iter":600000,"salt":"<base64>"}
    kdf JSONB NOT NULL CHECK (
        jsonb_typeof(kdf) = 'object'
        AND kdf->>'alg' = 'pbkdf2-hmac-sha256'
        AND (kdf->>'iter')::INT BETWEEN 100000 AND 10000000
        AND char_length(kdf->>'salt') BETWEEN 16 AND 64
    ),
    -- AES-256-GCM(nonce || wrapped 32-byte key || tag), base64. The server cannot unwrap it.
    wrapped_key TEXT NOT NULL CHECK (char_length(wrapped_key) BETWEEN 40 AND 200),
    key_check TEXT NOT NULL CHECK (char_length(key_check) BETWEEN 40 AND 200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_keys FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_keys_select_own" ON public.user_keys;
CREATE POLICY "user_keys_select_own" ON public.user_keys
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_keys_insert_own" ON public.user_keys;
CREATE POLICY "user_keys_insert_own" ON public.user_keys
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_keys_update_own" ON public.user_keys;
CREATE POLICY "user_keys_update_own" ON public.user_keys
    FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_keys_delete_own" ON public.user_keys;
CREATE POLICY "user_keys_delete_own" ON public.user_keys
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

REVOKE ALL ON public.user_keys FROM anon;

-- ----------------------------------------------------------------------------
-- 2. Collection snapshots: plaintext array or encrypted envelope {"v":1,"ct":"..."}
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_collections DROP CONSTRAINT IF EXISTS user_collections_data_check;
ALTER TABLE public.user_collections DROP CONSTRAINT IF EXISTS user_collections_data_shape;
ALTER TABLE public.user_collections ADD CONSTRAINT user_collections_data_shape CHECK (
    jsonb_typeof(data) = 'array'
    OR (jsonb_typeof(data) = 'object' AND jsonb_typeof(data->'ct') = 'string')
);
ALTER TABLE public.user_collections FORCE ROW LEVEL SECURITY;
REVOKE ALL ON public.user_collections FROM anon;

CREATE OR REPLACE FUNCTION public.enforce_e2ee_collections()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Once an account has an encryption key, a buggy or outdated client must not be
    -- able to upload readable data next to the ciphertext.
    IF jsonb_typeof(NEW.data) = 'array'
       AND EXISTS (SELECT 1 FROM public.user_keys k WHERE k.user_id = NEW.user_id) THEN
        RAISE EXCEPTION 'E2EE_REQUIRED: this account only accepts end-to-end encrypted data'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_e2ee ON public.user_collections;
CREATE TRIGGER trg_enforce_e2ee
    BEFORE INSERT OR UPDATE ON public.user_collections
    FOR EACH ROW EXECUTE FUNCTION public.enforce_e2ee_collections();

-- ----------------------------------------------------------------------------
-- 3. Two-step verification: data requires an AAL2 session when the user enrolled a factor
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mfa_satisfied()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_claims TEXT := current_setting('request.jwt.claims', true);
    v_has_factor BOOLEAN;
BEGIN
    IF coalesce(nullif(v_claims, '')::jsonb ->> 'aal', 'aal1') = 'aal2' THEN
        RETURN TRUE;
    END IF;
    -- Plain Postgres (docker-compose) has no MFA tables.
    IF to_regclass('auth.mfa_factors') IS NULL THEN
        RETURN TRUE;
    END IF;
    EXECUTE 'SELECT EXISTS (SELECT 1 FROM auth.mfa_factors WHERE user_id = $1 AND status::text = ''verified'')'
        INTO v_has_factor USING auth.uid();
    RETURN NOT v_has_factor;
END;
$$;

DROP POLICY IF EXISTS "user_collections_require_mfa" ON public.user_collections;
CREATE POLICY "user_collections_require_mfa" ON public.user_collections
    AS RESTRICTIVE FOR ALL TO authenticated
    USING (public.mfa_satisfied()) WITH CHECK (public.mfa_satisfied());

DROP POLICY IF EXISTS "user_keys_require_mfa" ON public.user_keys;
CREATE POLICY "user_keys_require_mfa" ON public.user_keys
    AS RESTRICTIVE FOR ALL TO authenticated
    USING (public.mfa_satisfied()) WITH CHECK (public.mfa_satisfied());

-- ----------------------------------------------------------------------------
-- 4a. Rate limiting is bound to the caller and only callable server-side
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
SET search_path = public, pg_temp
AS $$
DECLARE
    v_recent_count INT;
BEGIN
    -- A signed-in caller may only spend its own quota, never another user's.
    IF auth.uid() IS NOT NULL AND p_user_id IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'rate limit subject must be the caller' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF p_user_id IS NULL OR p_endpoint !~ '^[a-z0-9_-]{1,64}$'
       OR p_max_requests NOT BETWEEN 1 AND 10000 OR p_window_seconds NOT BETWEEN 1 AND 86400 THEN
        RAISE EXCEPTION 'invalid rate limit arguments' USING ERRCODE = 'invalid_parameter_value';
    END IF;

    DELETE FROM public.rate_limit_records WHERE request_timestamp < NOW() - INTERVAL '1 day';

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

-- ----------------------------------------------------------------------------
-- 4b. Audit events from clients are validated and throttled
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_security_event(
    p_event_type TEXT,
    p_severity TEXT DEFAULT 'INFO',
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_log_id UUID;
    v_uid UUID := auth.uid();
    v_recent INT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'authentication required' USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF p_event_type !~ '^[A-Z0-9_]{3,64}$' THEN
        RAISE EXCEPTION 'invalid event type' USING ERRCODE = 'invalid_parameter_value';
    END IF;
    -- Clients cannot forge CRITICAL entries; those come from server-side code only.
    IF p_severity NOT IN ('INFO', 'WARNING') AND coalesce(auth.role(), '') <> 'service_role' THEN
        p_severity := 'WARNING';
    END IF;
    IF p_metadata IS NULL OR jsonb_typeof(p_metadata) <> 'object' OR pg_column_size(p_metadata) > 2048 THEN
        p_metadata := '{}'::jsonb;
    END IF;

    SELECT COUNT(*) INTO v_recent FROM public.security_audit_logs
    WHERE user_id = v_uid AND created_at > NOW() - INTERVAL '1 minute';
    IF v_recent >= 60 THEN
        RETURN NULL; -- silently drop audit floods
    END IF;

    INSERT INTO public.security_audit_logs (user_id, event_type, severity, metadata, created_at)
    VALUES (v_uid, p_event_type, p_severity, p_metadata, NOW())
    RETURNING id INTO v_log_id;
    RETURN v_log_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 4c. Every SECURITY DEFINER function: pinned search_path, no anon/PUBLIC execute
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT p.oid::regprocedure AS sig, p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.prosecdef
    LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = public, extensions, pg_temp', r.sig);
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon', r.sig);
        IF r.proname = 'check_rate_limit' THEN
            -- Called by edge functions with the service role only.
            EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM authenticated', r.sig);
        ELSIF r.proname NOT IN ('enforce_e2ee_collections') THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.sig);
        END IF;
        EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', r.sig);
    END LOOP;
END
$$;

-- Rate-limit bookkeeping is never visible to clients.
REVOKE ALL ON public.rate_limit_records FROM anon, authenticated;
