-- ============================================================================
-- NOTtEodo Sovereign Bootstrap — Standalone Postgres & Auth Primitives
-- docker-init/00_standalone_auth.sql — STANDALONE POSTGRES ONLY. Never apply to Supabase:
-- it replaces auth.uid() with a stub that falls back to a fixed user id.
-- Ensures 100% turnkey compatibility with standalone PostgreSQL, Docker Compose,
-- and CI/CD test runners.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS auth;

-- The Supabase API roles that RLS policies and grants refer to.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN BYPASSRLS;
    END IF;
END
$$;

-- Create auth.users if not present (present in Supabase Cloud, absent in bare Postgres)
CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id UUID,
    email VARCHAR(255) UNIQUE,
    encrypted_password VARCHAR(255),
    email_confirmed_at TIMESTAMPTZ DEFAULT NOW(),
    invited_at TIMESTAMPTZ,
    confirmation_token VARCHAR(255),
    confirmation_sent_at TIMESTAMPTZ,
    recovery_token VARCHAR(255),
    recovery_sent_at TIMESTAMPTZ,
    email_change_token_new VARCHAR(255),
    email_change VARCHAR(255),
    email_change_sent_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ DEFAULT NOW(),
    raw_app_meta_data JSONB DEFAULT '{"provider":"email","providers":["email"]}'::jsonb,
    raw_user_meta_data JSONB DEFAULT '{"display_name":"Sanctuary Curator"}'::jsonb,
    is_super_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    phone VARCHAR(20) UNIQUE,
    phone_confirmed_at TIMESTAMPTZ,
    phone_change VARCHAR(20),
    phone_change_token VARCHAR(255),
    phone_change_sent_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ DEFAULT NOW(),
    email_change_token_current VARCHAR(255),
    email_change_confirm_status SMALLINT DEFAULT 0,
    banned_until TIMESTAMPTZ,
    reauthentication_token VARCHAR(255),
    reauthentication_sent_at TIMESTAMPTZ,
    is_sso_user BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ
);

-- Mock / Safe fallback for auth.uid() in non-Supabase standalone environments
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
    SELECT coalesce(
        nullif(current_setting('request.jwt.claim.sub', true), '')::uuid,
        '00000000-0000-0000-0000-000000000001'::uuid
    );
$$ LANGUAGE sql STABLE;

-- Mock / Safe fallback for auth.role() in non-Supabase standalone environments
CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT AS $$
    SELECT coalesce(
        nullif(current_setting('request.jwt.claim.role', true), ''),
        'authenticated'
    );
$$ LANGUAGE sql STABLE;

-- Mock / Safe fallback for auth.email() in non-Supabase standalone environments
CREATE OR REPLACE FUNCTION auth.email() RETURNS TEXT AS $$
    SELECT coalesce(
        nullif(current_setting('request.jwt.claim.email', true), ''),
        'curator@notteodo.sanctuary'
    );
$$ LANGUAGE sql STABLE;

-- Seed default sovereign curator user in auth.users if empty (for standalone testing)
INSERT INTO auth.users (id, email, raw_user_meta_data)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'curator@notteodo.sanctuary',
    '{"display_name":"Sovereign Master Curator"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
