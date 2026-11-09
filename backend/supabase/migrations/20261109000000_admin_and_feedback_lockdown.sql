-- Migration: server-side admins and locked-down feedback
--
-- Before this, public.user_feedback allowed anyone holding the public (anon) key to
-- read every row (including user_email), edit and delete them. Admin rights were
-- decided inside the app with a password compiled into the client.
--
-- After this:
--   * Admins are rows in public.app_admins, managed only with the service role
--     (Supabase dashboard / SQL editor). public.is_app_admin() reports the caller's status.
--   * Signed-in users submit feedback as themselves and read only their own.
--   * Only admins read all feedback, update its status/notes, or delete it.
--   * The anon role has no access to feedback at all.

CREATE TABLE IF NOT EXISTS public.app_admins (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT
);
ALTER TABLE public.app_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_admins FORCE ROW LEVEL SECURITY;
-- No policies: nobody but the service role can read or change the admin list.
REVOKE ALL ON public.app_admins FROM anon, authenticated;

CREATE OR REPLACE FUNCTION public.is_app_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (SELECT 1 FROM public.app_admins WHERE user_id = (SELECT auth.uid()));
$$;
REVOKE EXECUTE ON FUNCTION public.is_app_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_app_admin() TO authenticated, service_role;

-- Feedback ------------------------------------------------------------------

ALTER TABLE public.user_feedback FORCE ROW LEVEL SECURITY;
REVOKE ALL ON public.user_feedback FROM anon;

DROP POLICY IF EXISTS "Allow public feedback submission" ON public.user_feedback;
DROP POLICY IF EXISTS "Allow feedback reading" ON public.user_feedback;
DROP POLICY IF EXISTS "Allow feedback update" ON public.user_feedback;
DROP POLICY IF EXISTS "Allow feedback deletion" ON public.user_feedback;

-- Sizes keep a single row from being used to store or spray large payloads.
ALTER TABLE public.user_feedback DROP CONSTRAINT IF EXISTS user_feedback_sizes;
ALTER TABLE public.user_feedback ADD CONSTRAINT user_feedback_sizes CHECK (
    char_length(title) BETWEEN 1 AND 200
    AND char_length(description) BETWEEN 1 AND 5000
    AND char_length(user_identifier) <= 120
    AND (user_email IS NULL OR char_length(user_email) <= 320)
    AND (device_info IS NULL OR char_length(device_info) <= 500)
    AND (admin_notes IS NULL OR char_length(admin_notes) <= 5000)
) NOT VALID;

CREATE POLICY "feedback_insert_own" ON public.user_feedback
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND status = 'pending'
        AND admin_notes IS NULL
    );

CREATE POLICY "feedback_select_own_or_admin" ON public.user_feedback
    FOR SELECT TO authenticated
    USING (user_id = (SELECT auth.uid()) OR (SELECT public.is_app_admin()));

CREATE POLICY "feedback_update_admin" ON public.user_feedback
    FOR UPDATE TO authenticated
    USING ((SELECT public.is_app_admin()))
    WITH CHECK ((SELECT public.is_app_admin()));

CREATE POLICY "feedback_delete_admin" ON public.user_feedback
    FOR DELETE TO authenticated
    USING ((SELECT public.is_app_admin()));

-- At most 20 submissions per user per day, enforced in the database.
CREATE OR REPLACE FUNCTION public.limit_feedback_rate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF (SELECT COUNT(*) FROM public.user_feedback
         WHERE user_id = NEW.user_id AND created_at > NOW() - INTERVAL '1 day') >= 20 THEN
        RAISE EXCEPTION 'Too much feedback today. Please try again tomorrow.' USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.limit_feedback_rate() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_limit_feedback_rate ON public.user_feedback;
CREATE TRIGGER trg_limit_feedback_rate
    BEFORE INSERT ON public.user_feedback
    FOR EACH ROW EXECUTE FUNCTION public.limit_feedback_rate();

-- To make someone an admin (run in the SQL editor as the service role):
--   INSERT INTO public.app_admins (user_id, note)
--   SELECT id, 'owner' FROM auth.users WHERE email = 'you@example.com';
