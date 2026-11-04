-- Migration: 20261105000000_perf_indexes.sql
-- High-performance composite indexes for high-frequency queries, RLS scans, and delta syncs

-- 1. User collection sync queries
CREATE INDEX IF NOT EXISTS idx_user_collections_uid_coll ON public.user_collections (user_id, collection);
CREATE INDEX IF NOT EXISTS idx_user_collections_uid_updated ON public.user_collections (user_id, updated_at DESC);

-- 2. Notes lookup and sorting
CREATE INDEX IF NOT EXISTS idx_notes_user_updated ON public.notes (user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_space ON public.notes (user_id, space_id);

-- 3. Tasks filtering by completion status and due date
CREATE INDEX IF NOT EXISTS idx_tasks_user_status_created ON public.tasks (user_id, is_completed, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_user_due ON public.tasks (user_id, due_at);

-- 4. Expenses filtering and monthly aggregation
CREATE INDEX IF NOT EXISTS idx_expenses_user_spent_desc ON public.expenses (user_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user_category ON public.expenses (user_id, category);

-- 5. Habits tracking and daily logs
CREATE INDEX IF NOT EXISTS idx_habits_user_created ON public.habits (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_habit_logs_user_habit ON public.habit_logs (user_id, habit_id, completed_date);

-- 6. Moodboard pins
CREATE INDEX IF NOT EXISTS idx_moodboard_user_created ON public.moodboard_pins (user_id, created_at DESC);

-- 7. User encryption keys
CREATE INDEX IF NOT EXISTS idx_user_keys_user ON public.user_keys (user_id);

