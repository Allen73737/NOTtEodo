# ==============================================================================
# NOTtEodo Automated Supabase Deployment Script
# Deploys Database Migration & Edge Functions to project: zjmxwttdkvhiuampirwa
# ==============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN,
    [Parameter(Mandatory=$false)]
    [string]$GroqApiKey = $env:GROQ_API_KEY
)

$ErrorActionPreference = "Stop"
$PROJECT_REF = "zjmxwttdkvhiuampirwa"

if (-not $AccessToken) {
    Write-Host "SUPABASE_ACCESS_TOKEN is required. Set it in environment or pass -AccessToken <sbp_...>" -ForegroundColor Yellow
    exit 1
}

if (-not $GroqApiKey -and (Test-Path "backend/.env")) {
    $envMatch = Get-Content "backend/.env" | Select-String "^GROQ_API_KEY=(.+)$"
    if ($envMatch) { $GroqApiKey = $envMatch.Matches[0].Groups[1].Value }
}

$env:SUPABASE_ACCESS_TOKEN = $AccessToken

Write-Host "1. Linking project: $PROJECT_REF..." -ForegroundColor Cyan
npx --yes supabase link --workdir backend --project-ref $PROJECT_REF

Write-Host "2. Setting edge function environment secrets..." -ForegroundColor Cyan
if ($GroqApiKey) {
    npx --yes supabase secrets set --workdir backend GROQ_API_KEY="$GroqApiKey" --yes
}

Write-Host "3. Applying database migrations (Nodo memory and learning tables)..." -ForegroundColor Cyan
npx --yes supabase db push --workdir backend --yes

Write-Host "4. Deploying Edge Functions (ai-assist, scoped-ai)..." -ForegroundColor Cyan
npx --yes supabase functions deploy --workdir backend ai-assist --no-verify-jwt --yes
npx --yes supabase functions deploy --workdir backend scoped-ai --no-verify-jwt --yes

Write-Host "Deployment complete!" -ForegroundColor Green
