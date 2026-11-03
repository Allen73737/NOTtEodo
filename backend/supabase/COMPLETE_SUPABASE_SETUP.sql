-- =========================================================================
-- START: backend/supabase/migrations/20260905000000_full_schema.sql
-- =========================================================================

-- ============================================================================
-- NOTtEodo Production Database Architecture â€” Master Schema
-- Migration: 20260905000000_full_schema.sql
-- High Security, Zero-Knowledge Vault, pgvector RAG, & Full Module Coverage
-- ============================================================================

-- Extensions for Cryptographic UUIDs & High-Dimensional AI Vector Search
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- 1. Profiles & Security Posture
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL CHECK (char_length(display_name) <= 100),
    avatar_url TEXT CHECK (avatar_url IS NULL OR avatar_url ~* '^https?://'),
    timezone TEXT DEFAULT 'Asia/Kolkata' CHECK (char_length(timezone) <= 50),
    locale TEXT DEFAULT 'en_US' CHECK (char_length(locale) <= 10),
    is_2fa_enabled BOOLEAN DEFAULT FALSE,
    failed_login_count INT DEFAULT 0 CHECK (failed_login_count >= 0),
    locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    last_login_ip TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- 2. Spaces (Knowledge Collections & Sanctuaries)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.spaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) > 0 AND char_length(name) <= 120),
    description TEXT CHECK (char_length(description) <= 1000),
    cover_image_url TEXT,
    color TEXT DEFAULT '#E8927C' CHECK (color ~* '^#[0-9A-Fa-f]{6}$'),
    icon TEXT DEFAULT 'book-open' CHECK (char_length(icon) <= 50),
    space_type TEXT DEFAULT 'academic' CHECK (space_type IN ('academic', 'travel', 'wardrobe', 'design', 'personal')),
    is_archived BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_spaces_user_id ON public.spaces(user_id);

-- ============================================================================
-- 3. Notes (Tactile Knowledge & Spaces)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    space_id UUID REFERENCES public.spaces(id) ON DELETE SET NULL,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 255),
    content TEXT,
    excerpt TEXT,
    tag TEXT DEFAULT 'General' CHECK (char_length(tag) <= 60),
    is_pinned BOOLEAN DEFAULT FALSE NOT NULL,
    is_favorite BOOLEAN DEFAULT FALSE NOT NULL,
    is_archived BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notes_user_id ON public.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_space_id ON public.notes(space_id);
CREATE INDEX IF NOT EXISTS idx_notes_fts ON public.notes USING GIN (to_tsvector('english', title || ' ' || coalesce(excerpt, '') || ' ' || coalesce(content, '')));

-- ============================================================================
-- 4. Documents & RAG Vector Chunks (pgvector 1536-dim embeddings)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    space_id UUID NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) > 0 AND char_length(name) <= 255),
    file_url TEXT NOT NULL CHECK (file_url ~* '^https?://'),
    mime_type TEXT CHECK (char_length(mime_type) <= 100),
    file_size BIGINT CHECK (file_size > 0),
    page_count INT CHECK (page_count >= 0),
    processing_status TEXT DEFAULT 'ready' CHECK (processing_status IN ('pending', 'processing', 'ready', 'failed')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.document_chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    space_id UUID NOT NULL REFERENCES public.spaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chunk_index INT NOT NULL CHECK (chunk_index >= 0),
    content TEXT NOT NULL CHECK (char_length(content) > 0),
    page_number INT,
    embedding VECTOR(1536),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_chunks_user_space ON public.document_chunks(user_id, space_id);
CREATE INDEX IF NOT EXISTS idx_chunks_embedding ON public.document_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- ============================================================================
-- 5. Tasks (Tactile Priorities & Wax Seals)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    space_id UUID REFERENCES public.spaces(id) ON DELETE SET NULL,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 255),
    description TEXT,
    priority TEXT DEFAULT 'High' CHECK (priority IN ('Urgent', 'High', 'Medium', 'Low')),
    space_label TEXT DEFAULT 'General Space' CHECK (char_length(space_label) <= 100),
    time_slot TEXT DEFAULT 'Morning' CHECK (time_slot IN ('Morning', 'Afternoon', 'Evening', 'Later')),
    is_completed BOOLEAN DEFAULT FALSE NOT NULL,
    completed_at TIMESTAMPTZ,
    due_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_completed ON public.tasks(user_id, is_completed);

-- ============================================================================
-- 6. Events (Time-Ribbon Planner & Dial)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 255),
    scheduled_hour INT CHECK (scheduled_hour >= 0 AND scheduled_hour <= 23),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL CHECK (end_at >= start_at),
    event_type TEXT DEFAULT 'general' CHECK (event_type IN ('general', 'focus', 'meeting', 'reflection', 'travel')),
    is_synced_to_calendar BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_events_user_time ON public.events(user_id, start_at);

-- ============================================================================
-- 7. Habits & Daily Rhythms
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 200),
    time_label TEXT DEFAULT '08:00 AM' CHECK (char_length(time_label) <= 20),
    current_streak INT DEFAULT 0 CHECK (current_streak >= 0),
    best_streak INT DEFAULT 0 CHECK (best_streak >= 0),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.habit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    completed_date DATE DEFAULT CURRENT_DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(habit_id, completed_date)
);

CREATE INDEX IF NOT EXISTS idx_habit_logs_user_date ON public.habit_logs(user_id, completed_date);

-- ============================================================================
-- 8. Wardrobe Items & Outfits Lookbook
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.wardrobe_outfits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 200),
    items TEXT NOT NULL CHECK (char_length(items) <= 500),
    weather TEXT DEFAULT 'Mild Â· 22Â°C' CHECK (char_length(weather) <= 50),
    fabric TEXT DEFAULT 'Italian Linen' CHECK (char_length(fabric) <= 60),
    vibe TEXT DEFAULT 'College Casual' CHECK (char_length(vibe) <= 60),
    tags TEXT[] DEFAULT '{}',
    preview_icon TEXT DEFAULT 'shirt' CHECK (char_length(preview_icon) <= 50),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_outfits_user_id ON public.wardrobe_outfits(user_id);

-- ============================================================================
-- 9. Expenses, Receipts & Group Settlements
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 200),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    category TEXT DEFAULT 'General' CHECK (category IN ('Clothing', 'Food & Dining', 'Travel & Stay', 'Study & Books', 'Entertainment', 'Personal Care', 'General', 'Shopping')),
    expense_date DATE DEFAULT CURRENT_DATE NOT NULL,
    is_clipped_to_wardrobe BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.settlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    payer_name TEXT NOT NULL CHECK (char_length(payer_name) <= 100),
    payee_name TEXT NOT NULL CHECK (char_length(payee_name) <= 100),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    is_settled BOOLEAN DEFAULT FALSE NOT NULL,
    settled_at TIMESTAMPTZ,
    group_name TEXT DEFAULT 'Goa Trip 2026' CHECK (char_length(group_name) <= 120),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, expense_date);
CREATE INDEX IF NOT EXISTS idx_settlements_user_id ON public.settlements(user_id);

-- ============================================================================
-- 10. Travel Voyages & Packing Checklists
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 255),
    destination TEXT NOT NULL CHECK (char_length(destination) <= 120),
    flight_code TEXT DEFAULT 'TBD' CHECK (char_length(flight_code) <= 30),
    date_range TEXT NOT NULL CHECK (char_length(date_range) <= 100),
    budget NUMERIC(12,2) DEFAULT 0 CHECK (budget >= 0),
    status TEXT DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.packing_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 200),
    category TEXT DEFAULT 'Essentials' CHECK (char_length(category) <= 50),
    is_packed BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_trips_user_id ON public.trips(user_id);
CREATE INDEX IF NOT EXISTS idx_packing_trip_id ON public.packing_items(trip_id);

-- ============================================================================
-- 11. Shopping & Curated Goods Wishlist
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.shopping_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) > 0 AND char_length(name) <= 200),
    store TEXT DEFAULT 'General' CHECK (char_length(store) <= 100),
    price NUMERIC(10,2) DEFAULT 0 CHECK (price >= 0),
    is_checked BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_shopping_user_id ON public.shopping_items(user_id);

-- ============================================================================
-- 12. Memoirs & Voice Journal
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.memoirs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 255),
    audio_url TEXT,
    duration TEXT DEFAULT '0:00' CHECK (char_length(duration) <= 20),
    excerpt TEXT NOT NULL CHECK (char_length(excerpt) <= 2000),
    mood TEXT DEFAULT 'Reflective' CHECK (mood IN ('Reflective', 'Creative', 'Focused', 'Adventurous', 'Serene')),
    date_label TEXT DEFAULT 'Today' CHECK (char_length(date_label) <= 50),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_memoirs_user_id ON public.memoirs(user_id);

-- ============================================================================
-- 13. Moodboard & Visual Pins
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.moodboard_pins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 200),
    image_url TEXT NOT NULL CHECK (image_url ~* '^https?://'),
    handwritten_note TEXT CHECK (char_length(handwritten_note) <= 500),
    washi_tape_color TEXT DEFAULT '#E5DFC9',
    rubber_stamp_style TEXT DEFAULT 'curated',
    pin_date TEXT DEFAULT 'Today',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pins_user_id ON public.moodboard_pins(user_id);

-- ============================================================================
-- 14. Zero-Knowledge Encrypted Hidden Vault
-- Client-side AES-GCM-256 encrypted payload. Plaintext never touches the server.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.encrypted_vault (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(trim(title)) > 0 AND char_length(title) <= 200),
    encrypted_blob TEXT NOT NULL,          -- AES-GCM cipher payload in Base64
    salt TEXT NOT NULL,                    -- PBKDF2 / Argon2id salt
    nonce TEXT NOT NULL,                   -- 12-byte IV in Base64
    verification_hash TEXT NOT NULL,       -- Zero-knowledge challenge hash
    category TEXT DEFAULT 'Confidential',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_vault_user_id ON public.encrypted_vault(user_id);

-- ============================================================================
-- 15. Immutable Security Audit Log
-- Append-only. UPDATE and DELETE are strictly revoked in RLS.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.security_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL CHECK (char_length(event_type) <= 80),
    severity TEXT DEFAULT 'INFO' CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')),
    ip_address TEXT,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_user_event ON public.security_audit_logs(user_id, event_type);
CREATE INDEX IF NOT EXISTS idx_audit_created ON public.security_audit_logs(created_at DESC);


-- =========================================================================
-- START: backend/supabase/migrations/20260905000001_hardened_rls.sql
-- =========================================================================

-- ============================================================================
-- NOTtEodo Production Security Policies â€” Hardened Row Level Security (RLS)
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

CREATE OR REPLACE TRIGGER update_profiles_timestamp BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_spaces_timestamp BEFORE UPDATE ON public.spaces FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_notes_timestamp BEFORE UPDATE ON public.notes FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_tasks_timestamp BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_events_timestamp BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_habits_timestamp BEFORE UPDATE ON public.habits FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_outfits_timestamp BEFORE UPDATE ON public.wardrobe_outfits FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_trips_timestamp BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_shopping_timestamp BEFORE UPDATE ON public.shopping_items FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
CREATE OR REPLACE TRIGGER update_vault_timestamp BEFORE UPDATE ON public.encrypted_vault FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();


-- =========================================================================
-- START: backend/supabase/migrations/20260905000002_security_functions.sql
-- =========================================================================

-- ============================================================================
-- NOTtEodo Security & Intelligence Stored Procedures
-- Migration: 20260905000002_security_functions.sql
-- Anti-DDoS Rate Limiting, pgvector Semantic Matching, & Universal Query
-- ============================================================================

-- Rate Limiting Table for In-Database Sliding Window Defense
CREATE TABLE IF NOT EXISTS public.rate_limit_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    endpoint TEXT NOT NULL,
    request_timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_user_window ON public.rate_limit_records(user_id, endpoint, request_timestamp);

-- Enable RLS on rate limit records
ALTER TABLE public.rate_limit_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Rate limit system only" ON public.rate_limit_records;
CREATE POLICY "Rate limit system only" ON public.rate_limit_records FOR ALL TO service_role USING (true);

-- 1. Anti-DDoS & Brute-Force Rate Limiting Function
CREATE OR REPLACE FUNCTION public.check_rate_limit(
    p_user_id UUID,
    p_endpoint TEXT,
    p_max_requests INT DEFAULT 60,
    p_window_seconds INT DEFAULT 60
)
RETURNS BOOLEAN AS $$
DECLARE
    v_recent_count INT;
    v_cutoff TIMESTAMPTZ := NOW() - (p_window_seconds || ' seconds')::INTERVAL;
BEGIN
    -- Prune old records periodically
    DELETE FROM public.rate_limit_records 
    WHERE request_timestamp < NOW() - INTERVAL '10 minutes';

    -- Count requests in window
    SELECT COUNT(*) INTO v_recent_count
    FROM public.rate_limit_records
    WHERE user_id = p_user_id
      AND endpoint = p_endpoint
      AND request_timestamp >= v_cutoff;

    IF v_recent_count >= p_max_requests THEN
        -- Log Security Warning
        INSERT INTO public.security_audit_logs (user_id, event_type, severity, metadata)
        VALUES (
            p_user_id,
            'RATE_LIMIT_EXCEEDED',
            'WARNING',
            jsonb_build_object(
                'endpoint', p_endpoint,
                'requests_in_window', v_recent_count,
                'limit', p_max_requests,
                'window_seconds', p_window_seconds
            )
        );
        RETURN FALSE; -- Rate limited!
    END IF;

    -- Record current request
    INSERT INTO public.rate_limit_records (user_id, endpoint, request_timestamp)
    VALUES (p_user_id, p_endpoint, NOW());

    RETURN TRUE; -- Allowed
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Semantic Document Vector Similarity Match (pgvector RAG)
CREATE OR REPLACE FUNCTION public.match_documents(
    query_embedding VECTOR(1536),
    match_count INT DEFAULT 5,
    filter_space_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    document_id UUID,
    space_id UUID,
    content TEXT,
    page_number INT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        dc.id,
        dc.document_id,
        dc.space_id,
        dc.content,
        dc.page_number,
        1 - (dc.embedding <=> query_embedding) AS similarity
    FROM public.document_chunks dc
    WHERE dc.user_id = auth.uid()
      AND (filter_space_id IS NULL OR dc.space_id = filter_space_id)
    ORDER BY dc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Security Event Logging Stored Procedure
CREATE OR REPLACE FUNCTION public.log_security_event(
    p_event_type TEXT,
    p_severity TEXT DEFAULT 'INFO',
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO public.security_audit_logs (
        user_id,
        event_type,
        severity,
        metadata,
        created_at
    )
    VALUES (
        auth.uid(),
        p_event_type,
        p_severity,
        p_metadata,
        NOW()
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Server-Side Universal Search
CREATE OR REPLACE FUNCTION public.search_sanctuary_universal(
    search_query TEXT,
    max_results INT DEFAULT 20
)
RETURNS TABLE (
    entity_type TEXT,
    entity_id UUID,
    title TEXT,
    subtitle TEXT,
    relevance FLOAT
) AS $$
DECLARE
    clean_query TEXT := trim(search_query);
BEGIN
    IF char_length(clean_query) = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    -- Notes
    SELECT 
        'Note'::TEXT AS entity_type,
        n.id AS entity_id,
        n.title,
        COALESCE(n.tag, 'Note') || ' Â· ' || COALESCE(n.excerpt, '') AS subtitle,
        ts_rank_cd(to_tsvector('english', n.title || ' ' || coalesce(n.content, '')), plainto_tsquery('english', clean_query)) AS relevance
    FROM public.notes n
    WHERE n.user_id = auth.uid()
      AND to_tsvector('english', n.title || ' ' || coalesce(n.content, '')) @@ plainto_tsquery('english', clean_query)
    
    UNION ALL
    
    -- Tasks
    SELECT
        'Task'::TEXT AS entity_type,
        t.id AS entity_id,
        t.title,
        t.priority || ' Priority Â· ' || t.time_slot AS subtitle,
        CASE WHEN t.title ILIKE '%' || clean_query || '%' THEN 1.0 ELSE 0.5 END AS relevance
    FROM public.tasks t
    WHERE t.user_id = auth.uid()
      AND t.title ILIKE '%' || clean_query || '%'
    
    UNION ALL

    -- Expenses
    SELECT
        'Expense'::TEXT AS entity_type,
        e.id AS entity_id,
        e.title,
        e.category || ' Â· â‚¹' || e.amount::TEXT AS subtitle,
        CASE WHEN e.title ILIKE '%' || clean_query || '%' THEN 1.0 ELSE 0.5 END AS relevance
    FROM public.expenses e
    WHERE e.user_id = auth.uid()
      AND e.title ILIKE '%' || clean_query || '%'

    UNION ALL

    -- Outfits
    SELECT
        'Wardrobe'::TEXT AS entity_type,
        w.id AS entity_id,
        w.title,
        w.vibe || ' Â· ' || w.fabric AS subtitle,
        CASE WHEN w.title ILIKE '%' || clean_query || '%' THEN 1.0 ELSE 0.5 END AS relevance
    FROM public.wardrobe_outfits w
    WHERE w.user_id = auth.uid()
      AND (w.title ILIKE '%' || clean_query || '%' OR w.fabric ILIKE '%' || clean_query || '%')

    ORDER BY relevance DESC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- =========================================================================
-- START: backend/supabase/migrations/20261101000000_user_collections_sync.sql
-- =========================================================================

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


-- =========================================================================
-- START: backend/supabase/migrations/20261102000000_security_hardening.sql
-- =========================================================================

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


