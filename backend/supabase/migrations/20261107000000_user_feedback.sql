-- Migration: User Feedback and Feature Suggestions System
-- Allows sanctuary curators to submit feedback/suggestions, and administrators to review, plan, and resolve them.

CREATE TABLE IF NOT EXISTS public.user_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_identifier TEXT NOT NULL DEFAULT 'Curator',
    user_email TEXT,
    type TEXT NOT NULL DEFAULT 'feature_suggestion', -- 'feature_suggestion', 'general_feedback', 'bug_report', 'ui_enhancement'
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    impact TEXT NOT NULL DEFAULT 'nice_to_have', -- 'nice_to_have', 'important', 'critical'
    category TEXT NOT NULL DEFAULT 'General',
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'reviewed', 'planned', 'resolved'
    admin_notes TEXT,
    device_info TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_feedback_status ON public.user_feedback(status);
CREATE INDEX IF NOT EXISTS idx_user_feedback_type ON public.user_feedback(type);
CREATE INDEX IF NOT EXISTS idx_user_feedback_created_at ON public.user_feedback(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_feedback_user_id ON public.user_feedback(user_id);

-- RLS Policies
DROP POLICY IF EXISTS "Allow public feedback submission" ON public.user_feedback;
CREATE POLICY "Allow public feedback submission" 
ON public.user_feedback 
FOR INSERT 
TO public 
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow feedback reading" ON public.user_feedback;
CREATE POLICY "Allow feedback reading" 
ON public.user_feedback 
FOR SELECT 
TO public 
USING (true);

DROP POLICY IF EXISTS "Allow feedback update" ON public.user_feedback;
CREATE POLICY "Allow feedback update" 
ON public.user_feedback 
FOR UPDATE 
TO public 
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow feedback deletion" ON public.user_feedback;
CREATE POLICY "Allow feedback deletion" 
ON public.user_feedback 
FOR DELETE 
TO public 
USING (true);

