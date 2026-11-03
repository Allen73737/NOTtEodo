#!/usr/bin/env bash
set -e

# ==============================================================================
# NOTtEodo Automated Supabase Deployment Script (Bash)
# Deploys Database Migration & Edge Functions to project: zjmxwttdkvhiuampirwa
# ==============================================================================

PROJECT_REF="zjmxwttdkvhiuampirwa"

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "SUPABASE_ACCESS_TOKEN is required. Set it in environment: export SUPABASE_ACCESS_TOKEN=sbp_..."
    exit 1
fi

if [ -z "$GROQ_API_KEY" ] && [ -f "backend/.env" ]; then
    GROQ_API_KEY=$(grep -E '^GROQ_API_KEY=' backend/.env | cut -d '=' -f2-)
fi

echo "1. Linking project: $PROJECT_REF..."
npx --yes supabase link --workdir backend --project-ref "$PROJECT_REF"

echo "2. Setting edge function secrets..."
if [ -n "$GROQ_API_KEY" ]; then
    npx --yes supabase secrets set --workdir backend GROQ_API_KEY="$GROQ_API_KEY" --yes
fi

echo "3. Deploying Edge Function (ai-assist)..."
npx --yes supabase functions deploy --workdir backend ai-assist --no-verify-jwt --yes

echo "Deployment complete!"
