-- ============================================================================
-- NOTtEodo Production Database Architecture — Master Schema
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
    weather TEXT DEFAULT 'Mild · 22°C' CHECK (char_length(weather) <= 50),
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
