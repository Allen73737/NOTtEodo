-- ============================================================================
-- NOTtEodo Collection Snapshot Sync
-- Migration: 20261101000000_user_collections_sync.sql
--
-- The app is local-first: each module (notes, tasks, expenses, ...) is stored on
-- the device as a JSON list. When signed in, the client mirrors each list to one
-- row here. Rows are only ever visible to their owner.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_collections (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    collection TEXT NOT NULL CHECK (collection ~ '^[a-z_]{1,40}$'),
    data JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(data) = 'array'),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, collection)
);

-- Guard against runaway payloads (~5 MB per collection).
ALTER TABLE public.user_collections
    DROP CONSTRAINT IF EXISTS user_collections_size_limit;
ALTER TABLE public.user_collections
    ADD CONSTRAINT user_collections_size_limit CHECK (pg_column_size(data) < 5242880);

ALTER TABLE public.user_collections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_collections_select_own" ON public.user_collections;
CREATE POLICY "user_collections_select_own" ON public.user_collections
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_collections_insert_own" ON public.user_collections;
CREATE POLICY "user_collections_insert_own" ON public.user_collections
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_collections_update_own" ON public.user_collections;
CREATE POLICY "user_collections_update_own" ON public.user_collections
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_collections_delete_own" ON public.user_collections;
CREATE POLICY "user_collections_delete_own" ON public.user_collections
    FOR DELETE USING (auth.uid() = user_id);
