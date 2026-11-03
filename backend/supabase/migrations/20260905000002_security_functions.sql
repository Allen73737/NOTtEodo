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
        COALESCE(n.tag, 'Note') || ' · ' || COALESCE(n.excerpt, '') AS subtitle,
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
        t.priority || ' Priority · ' || t.time_slot AS subtitle,
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
        e.category || ' · ₹' || e.amount::TEXT AS subtitle,
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
        w.vibe || ' · ' || w.fabric AS subtitle,
        CASE WHEN w.title ILIKE '%' || clean_query || '%' THEN 1.0 ELSE 0.5 END AS relevance
    FROM public.wardrobe_outfits w
    WHERE w.user_id = auth.uid()
      AND (w.title ILIKE '%' || clean_query || '%' OR w.fabric ILIKE '%' || clean_query || '%')

    ORDER BY relevance DESC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
