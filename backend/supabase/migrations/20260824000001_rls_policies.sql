-- ============================================================================
-- NOTtEodo Row Level Security (RLS) Policies (rls_policies.sql)
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

-- Profiles: Users manage their own profile
CREATE POLICY "Users access own profile" ON public.profiles
    FOR ALL USING (auth.uid() = id);

-- Spaces: Users manage their own spaces
CREATE POLICY "Users access own spaces" ON public.spaces
    FOR ALL USING (auth.uid() = user_id);

-- Notes: Users manage their own notes
CREATE POLICY "Users access own notes" ON public.notes
    FOR ALL USING (auth.uid() = user_id);

-- Documents: Users access own documents
CREATE POLICY "Users access own documents" ON public.documents
    FOR ALL USING (auth.uid() = user_id);

-- Document Chunks: Users access own document chunks
CREATE POLICY "Users access own chunks" ON public.document_chunks
    FOR ALL USING (auth.uid() = user_id);

-- Tasks: Users access own tasks
CREATE POLICY "Users access own tasks" ON public.tasks
    FOR ALL USING (auth.uid() = user_id);

-- Events: Users access own events
CREATE POLICY "Users access own events" ON public.events
    FOR ALL USING (auth.uid() = user_id);

-- Wardrobe: Users access own wardrobe
CREATE POLICY "Users access own wardrobe" ON public.wardrobe_items
    FOR ALL USING (auth.uid() = user_id);

-- Expenses & Splitter
CREATE POLICY "Users access own expenses" ON public.expenses
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users access own groups" ON public.expense_groups
    FOR ALL USING (auth.uid() = user_id);

-- Trips
CREATE POLICY "Users access own trips" ON public.trips
    FOR ALL USING (auth.uid() = user_id);
