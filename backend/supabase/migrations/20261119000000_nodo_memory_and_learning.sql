-- ============================================================================
-- NOTtEodo: Nodo memory and learning
-- Migration: 20261119000000_nodo_memory_and_learning.sql
--
-- 1. nodo_memories      what Nodo has learned about each account (facts, preferences,
--                       goals). Only the ai-assist function (service role) writes them;
--                       the owner can read and delete their own, nobody else can see them.
-- 2. nodo_threads       a rolling summary of each account's past chats, so Nodo keeps
--                       context beyond the last few messages.
-- 3. nodo_turns         short-lived record of recent answers, so a thumbs up or down can
--                       be tied back to the question. No personal text: only the
--                       de-personalised app question and answer, if any. Kept 30 days.
-- 4. nodo_app_insights  what people commonly ask about using the app, shared by every
--                       account but holding no user id or personal text. Well-rated
--                       answers become approved knowledge for everyone; admins review.
-- ============================================================================

-- 1. Per-account memories ----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.nodo_memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL DEFAULT 'fact' CHECK (kind IN ('fact', 'preference', 'goal', 'style', 'person', 'routine')),
    content TEXT NOT NULL CHECK (char_length(content) BETWEEN 3 AND 300),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS nodo_memories_user_content ON public.nodo_memories (user_id, lower(content));
CREATE INDEX IF NOT EXISTS nodo_memories_user_recent ON public.nodo_memories (user_id, last_seen_at DESC);

ALTER TABLE public.nodo_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nodo_memories FORCE ROW LEVEL SECURITY;
REVOKE ALL ON public.nodo_memories FROM anon;
REVOKE INSERT, UPDATE ON public.nodo_memories FROM authenticated;
GRANT SELECT, DELETE ON public.nodo_memories TO authenticated;

DROP POLICY IF EXISTS "nodo_memories_select_own" ON public.nodo_memories;
CREATE POLICY "nodo_memories_select_own" ON public.nodo_memories
    FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS "nodo_memories_delete_own" ON public.nodo_memories;
CREATE POLICY "nodo_memories_delete_own" ON public.nodo_memories
    FOR DELETE TO authenticated USING (user_id = (SELECT auth.uid()));

-- At most 150 memories per account: the oldest-seen ones make room.
CREATE OR REPLACE FUNCTION public.nodo_trim_memories()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    DELETE FROM public.nodo_memories
     WHERE id IN (
        SELECT id FROM public.nodo_memories
         WHERE user_id = NEW.user_id
         ORDER BY last_seen_at DESC
         OFFSET 150
     );
    RETURN NULL;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.nodo_trim_memories() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_nodo_trim_memories ON public.nodo_memories;
CREATE TRIGGER trg_nodo_trim_memories
    AFTER INSERT ON public.nodo_memories
    FOR EACH ROW EXECUTE FUNCTION public.nodo_trim_memories();

-- 2. Conversation summary ----------------------------------------------------
CREATE TABLE IF NOT EXISTS public.nodo_threads (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    summary TEXT NOT NULL DEFAULT '' CHECK (char_length(summary) <= 2000),
    turns INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE public.nodo_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nodo_threads FORCE ROW LEVEL SECURITY;
REVOKE ALL ON public.nodo_threads FROM anon;
REVOKE INSERT, UPDATE ON public.nodo_threads FROM authenticated;
GRANT SELECT, DELETE ON public.nodo_threads TO authenticated;

DROP POLICY IF EXISTS "nodo_threads_select_own" ON public.nodo_threads;
CREATE POLICY "nodo_threads_select_own" ON public.nodo_threads
    FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));
DROP POLICY IF EXISTS "nodo_threads_delete_own" ON public.nodo_threads;
CREATE POLICY "nodo_threads_delete_own" ON public.nodo_threads
    FOR DELETE TO authenticated USING (user_id = (SELECT auth.uid()));

-- 3. Recent answers, for ratings (service role only) -------------------------
CREATE TABLE IF NOT EXISTS public.nodo_turns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    topic TEXT CHECK (topic IS NULL OR topic ~ '^[a-z0-9_]{2,48}$'),
    generic_question TEXT CHECK (generic_question IS NULL OR char_length(generic_question) <= 300),
    generic_answer TEXT CHECK (generic_answer IS NULL OR char_length(generic_answer) <= 1200),
    rating SMALLINT CHECK (rating IN (-1, 1)),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nodo_turns_created ON public.nodo_turns (created_at);
ALTER TABLE public.nodo_turns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nodo_turns FORCE ROW LEVEL SECURITY;
REVOKE ALL ON public.nodo_turns FROM anon, authenticated;

-- 4. Shared app knowledge learned from questions -----------------------------
CREATE TABLE IF NOT EXISTS public.nodo_app_insights (
    topic TEXT PRIMARY KEY CHECK (topic ~ '^[a-z0-9_]{2,48}$'),
    question TEXT NOT NULL CHECK (char_length(question) BETWEEN 3 AND 300),
    answer TEXT CHECK (answer IS NULL OR char_length(answer) <= 1200),
    hits INT NOT NULL DEFAULT 1,
    score INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'candidate' CHECK (status IN ('candidate', 'approved', 'rejected')),
    reviewed_by_admin BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS nodo_app_insights_status ON public.nodo_app_insights (status, hits DESC);
ALTER TABLE public.nodo_app_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nodo_app_insights FORCE ROW LEVEL SECURITY;
REVOKE ALL ON public.nodo_app_insights FROM anon;
REVOKE INSERT ON public.nodo_app_insights FROM authenticated;
GRANT SELECT, UPDATE, DELETE ON public.nodo_app_insights TO authenticated;

DROP POLICY IF EXISTS "nodo_insights_admin_select" ON public.nodo_app_insights;
CREATE POLICY "nodo_insights_admin_select" ON public.nodo_app_insights
    FOR SELECT TO authenticated USING ((SELECT public.is_app_admin()));
DROP POLICY IF EXISTS "nodo_insights_admin_update" ON public.nodo_app_insights;
CREATE POLICY "nodo_insights_admin_update" ON public.nodo_app_insights
    FOR UPDATE TO authenticated
    USING ((SELECT public.is_app_admin()))
    WITH CHECK ((SELECT public.is_app_admin()));
DROP POLICY IF EXISTS "nodo_insights_admin_delete" ON public.nodo_app_insights;
CREATE POLICY "nodo_insights_admin_delete" ON public.nodo_app_insights
    FOR DELETE TO authenticated USING ((SELECT public.is_app_admin()));

-- Counts one more asking of an app question (service role only).
CREATE OR REPLACE FUNCTION public.nodo_note_question(p_topic TEXT, p_question TEXT)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    INSERT INTO public.nodo_app_insights AS i (topic, question)
    VALUES (p_topic, p_question)
    ON CONFLICT (topic) DO UPDATE SET hits = i.hits + 1, updated_at = NOW();
$$;
REVOKE EXECUTE ON FUNCTION public.nodo_note_question(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.nodo_note_question(TEXT, TEXT) TO service_role;

-- Applies a rating to an insight. A well-rated answer replaces the stored one, and an
-- insight asked often enough with a net positive score is approved for everyone,
-- unless an admin has already ruled on it.
CREATE OR REPLACE FUNCTION public.nodo_rate_insight(p_topic TEXT, p_rating INT, p_answer TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF p_rating NOT IN (-1, 1) THEN
        RAISE EXCEPTION 'invalid rating' USING ERRCODE = 'invalid_parameter_value';
    END IF;
    UPDATE public.nodo_app_insights
       SET score = score + p_rating,
           answer = CASE WHEN p_rating = 1 AND p_answer IS NOT NULL AND char_length(p_answer) BETWEEN 10 AND 1200
                         AND NOT reviewed_by_admin THEN p_answer ELSE answer END,
           status = CASE
               WHEN reviewed_by_admin THEN status
               WHEN score + p_rating >= 3 AND hits >= 5 AND (answer IS NOT NULL OR (p_rating = 1 AND p_answer IS NOT NULL)) THEN 'approved'
               WHEN score + p_rating <= -3 THEN 'rejected'
               ELSE status END,
           updated_at = NOW()
     WHERE topic = p_topic;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.nodo_rate_insight(TEXT, INT, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.nodo_rate_insight(TEXT, INT, TEXT) TO service_role;

-- 5. Retention ---------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pg_cron') THEN
        CREATE EXTENSION IF NOT EXISTS pg_cron;
        PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname = 'nt_prune_nodo_turns';
        PERFORM cron.schedule('nt_prune_nodo_turns', '23 4 * * *',
            $job$DELETE FROM public.nodo_turns WHERE created_at < NOW() - INTERVAL '30 days'$job$);
    END IF;
EXCEPTION WHEN insufficient_privilege OR undefined_function THEN
    RAISE NOTICE 'pg_cron not available; nodo_turns is pruned by ai-assist.';
END
$$;
