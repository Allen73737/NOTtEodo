-- ============================================================================
-- NOTtEodo Production Security Policies — Hardened Row Level Security (RLS)
-- Migration: 20260905000001_hardened_rls.sql
-- Zero Trust Architecture, Strict Multi-Tenant Isolation, Anti-Tamper Audit
-- ============================================================================

-- 1. Enable RLS unconditionally on all application tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wardrobe_outfits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packing_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memoirs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moodboard_pins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encrypted_vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES: Users can read and update ONLY their own profile
-- ============================================================================
DROP POLICY IF EXISTS "Profiles select own" ON public.profiles;
CREATE POLICY "Profiles select own" ON public.profiles
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Profiles update own" ON public.profiles;
CREATE POLICY "Profiles update own" ON public.profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================================================
-- SPACES: Strict ownership enforcement
-- ============================================================================
DROP POLICY IF EXISTS "Spaces select own" ON public.spaces;
CREATE POLICY "Spaces select own" ON public.spaces
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Spaces insert own" ON public.spaces;
CREATE POLICY "Spaces insert own" ON public.spaces
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Spaces update own" ON public.spaces;
CREATE POLICY "Spaces update own" ON public.spaces
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Spaces delete own" ON public.spaces;
CREATE POLICY "Spaces delete own" ON public.spaces
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- NOTES: Explicit CRUD policies with space ownership validation
-- ============================================================================
DROP POLICY IF EXISTS "Notes select own" ON public.notes;
CREATE POLICY "Notes select own" ON public.notes
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Notes insert own" ON public.notes;
CREATE POLICY "Notes insert own" ON public.notes
    FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = user_id 
        AND (space_id IS NULL OR EXISTS (SELECT 1 FROM public.spaces WHERE id = space_id AND user_id = auth.uid()))
    );

DROP POLICY IF EXISTS "Notes update own" ON public.notes;
CREATE POLICY "Notes update own" ON public.notes
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id
        AND (space_id IS NULL OR EXISTS (SELECT 1 FROM public.spaces WHERE id = space_id AND user_id = auth.uid()))
    );

DROP POLICY IF EXISTS "Notes delete own" ON public.notes;
CREATE POLICY "Notes delete own" ON public.notes
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- DOCUMENTS & CHUNKS: Cross-tenant leakage prevention
-- ============================================================================
DROP POLICY IF EXISTS "Docs select own" ON public.documents;
CREATE POLICY "Docs select own" ON public.documents
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Docs insert own" ON public.documents;
CREATE POLICY "Docs insert own" ON public.documents
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Docs delete own" ON public.documents;
CREATE POLICY "Docs delete own" ON public.documents
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Chunks select own" ON public.document_chunks;
CREATE POLICY "Chunks select own" ON public.document_chunks
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Chunks insert own" ON public.document_chunks;
CREATE POLICY "Chunks insert own" ON public.document_chunks
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Chunks delete own" ON public.document_chunks;
CREATE POLICY "Chunks delete own" ON public.document_chunks
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- TASKS: CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Tasks select own" ON public.tasks;
CREATE POLICY "Tasks select own" ON public.tasks
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Tasks insert own" ON public.tasks;
CREATE POLICY "Tasks insert own" ON public.tasks
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Tasks update own" ON public.tasks;
CREATE POLICY "Tasks update own" ON public.tasks
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Tasks delete own" ON public.tasks;
CREATE POLICY "Tasks delete own" ON public.tasks
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- EVENTS (Planner): CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Events select own" ON public.events;
CREATE POLICY "Events select own" ON public.events
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Events insert own" ON public.events;
CREATE POLICY "Events insert own" ON public.events
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Events update own" ON public.events;
CREATE POLICY "Events update own" ON public.events
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Events delete own" ON public.events;
CREATE POLICY "Events delete own" ON public.events
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- HABITS & LOGS: CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Habits select own" ON public.habits;
CREATE POLICY "Habits select own" ON public.habits
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Habits insert own" ON public.habits;
CREATE POLICY "Habits insert own" ON public.habits
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Habits update own" ON public.habits;
CREATE POLICY "Habits update own" ON public.habits
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Habits delete own" ON public.habits;
CREATE POLICY "Habits delete own" ON public.habits
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Habit logs select own" ON public.habit_logs;
CREATE POLICY "Habit logs select own" ON public.habit_logs
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Habit logs insert own" ON public.habit_logs;
CREATE POLICY "Habit logs insert own" ON public.habit_logs
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Habit logs delete own" ON public.habit_logs;
CREATE POLICY "Habit logs delete own" ON public.habit_logs
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- WARDROBE OUTFITS: CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Outfits select own" ON public.wardrobe_outfits;
CREATE POLICY "Outfits select own" ON public.wardrobe_outfits
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Outfits insert own" ON public.wardrobe_outfits;
CREATE POLICY "Outfits insert own" ON public.wardrobe_outfits
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Outfits update own" ON public.wardrobe_outfits;
CREATE POLICY "Outfits update own" ON public.wardrobe_outfits
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Outfits delete own" ON public.wardrobe_outfits;
CREATE POLICY "Outfits delete own" ON public.wardrobe_outfits
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- EXPENSES & SETTLEMENTS: CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Expenses select own" ON public.expenses;
CREATE POLICY "Expenses select own" ON public.expenses
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Expenses insert own" ON public.expenses;
CREATE POLICY "Expenses insert own" ON public.expenses
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Expenses delete own" ON public.expenses;
CREATE POLICY "Expenses delete own" ON public.expenses
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Settlements select own" ON public.settlements;
CREATE POLICY "Settlements select own" ON public.settlements
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Settlements insert own" ON public.settlements;
CREATE POLICY "Settlements insert own" ON public.settlements
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Settlements update own" ON public.settlements;
CREATE POLICY "Settlements update own" ON public.settlements
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- TRIPS & PACKING ITEMS: CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Trips select own" ON public.trips;
CREATE POLICY "Trips select own" ON public.trips
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Trips insert own" ON public.trips;
CREATE POLICY "Trips insert own" ON public.trips
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Trips update own" ON public.trips;
CREATE POLICY "Trips update own" ON public.trips
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Trips delete own" ON public.trips;
CREATE POLICY "Trips delete own" ON public.trips
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Packing select own" ON public.packing_items;
CREATE POLICY "Packing select own" ON public.packing_items
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Packing insert own" ON public.packing_items;
CREATE POLICY "Packing insert own" ON public.packing_items
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Packing update own" ON public.packing_items;
CREATE POLICY "Packing update own" ON public.packing_items
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Packing delete own" ON public.packing_items;
CREATE POLICY "Packing delete own" ON public.packing_items
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- SHOPPING ITEMS: CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Shopping select own" ON public.shopping_items;
CREATE POLICY "Shopping select own" ON public.shopping_items
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Shopping insert own" ON public.shopping_items;
CREATE POLICY "Shopping insert own" ON public.shopping_items
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Shopping update own" ON public.shopping_items;
CREATE POLICY "Shopping update own" ON public.shopping_items
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Shopping delete own" ON public.shopping_items;
CREATE POLICY "Shopping delete own" ON public.shopping_items
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- MEMOIRS & PINS: CRUD Policies
-- ============================================================================
DROP POLICY IF EXISTS "Memoirs select own" ON public.memoirs;
CREATE POLICY "Memoirs select own" ON public.memoirs
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Memoirs insert own" ON public.memoirs;
CREATE POLICY "Memoirs insert own" ON public.memoirs
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Memoirs delete own" ON public.memoirs;
CREATE POLICY "Memoirs delete own" ON public.memoirs
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pins select own" ON public.moodboard_pins;
CREATE POLICY "Pins select own" ON public.moodboard_pins
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pins insert own" ON public.moodboard_pins;
CREATE POLICY "Pins insert own" ON public.moodboard_pins
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pins delete own" ON public.moodboard_pins;
CREATE POLICY "Pins delete own" ON public.moodboard_pins
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- ENCRYPTED VAULT: Zero-Knowledge Privacy Policies
-- ============================================================================
DROP POLICY IF EXISTS "Vault select own" ON public.encrypted_vault;
CREATE POLICY "Vault select own" ON public.encrypted_vault
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Vault insert own" ON public.encrypted_vault;
CREATE POLICY "Vault insert own" ON public.encrypted_vault
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Vault update own" ON public.encrypted_vault;
CREATE POLICY "Vault update own" ON public.encrypted_vault
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Vault delete own" ON public.encrypted_vault;
CREATE POLICY "Vault delete own" ON public.encrypted_vault
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- ============================================================================
-- IMMUTABLE SECURITY AUDIT LOGS: Append-Only Protection
-- Users can only insert audit logs or read their own logs.
-- UPDATE and DELETE are completely revoked!
-- ============================================================================
DROP POLICY IF EXISTS "Audit logs select own" ON public.security_audit_logs;
CREATE POLICY "Audit logs select own" ON public.security_audit_logs
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Audit logs insert authenticated" ON public.security_audit_logs;
CREATE POLICY "Audit logs insert authenticated" ON public.security_audit_logs
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Explicitly revoke tampering privileges
REVOKE UPDATE, DELETE, TRUNCATE ON public.security_audit_logs FROM authenticated, anon;

-- ============================================================================
-- DATABASE TRIGGERS: Auto Profile Creation on User Signup
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1), 'Sanctuary Voyager'),
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ============================================================================
-- TRIGGER: Auto-update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_timestamp BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_spaces_timestamp BEFORE UPDATE ON public.spaces FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_notes_timestamp BEFORE UPDATE ON public.notes FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_tasks_timestamp BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_events_timestamp BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_habits_timestamp BEFORE UPDATE ON public.habits FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_outfits_timestamp BEFORE UPDATE ON public.wardrobe_outfits FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_trips_timestamp BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_shopping_timestamp BEFORE UPDATE ON public.shopping_items FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE TRIGGER update_vault_timestamp BEFORE UPDATE ON public.encrypted_vault FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
