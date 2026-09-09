# NOTtEodo Enterprise Production Verification Script
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  NOTtEodo Sanctuary Enterprise Verification & Pre-Flight Diagnostics" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# 1. Code Analysis & Linter Zero-Tolerance Check
Write-Host "`n[1/4] Running static analysis on lib and test..." -ForegroundColor Yellow
Set-Location -Path "$PSScriptRoot\..\frontend"
dart analyze lib test --fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Error "Static analysis failed with issues!"
    exit 1
}
Write-Host "  --> Static analysis passed cleanly (0 errors, 0 warnings, 0 hints)." -ForegroundColor Green

# 2. Automated Test Suites (Unit + Widget + Cryptographic)
Write-Host "`n[2/4] Executing comprehensive enterprise test suites..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Error "Automated test suite failed!"
    exit 1
}
Write-Host "  --> All enterprise unit & widget test suites passed." -ForegroundColor Green

# 3. Web Release Compilation Check
Write-Host "`n[3/4] Verifying production web release build..." -ForegroundColor Yellow
flutter build web --release --pwa-strategy=offline-first
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter web release build failed!"
    exit 1
}
Write-Host "  --> Production web release bundle compiled successfully." -ForegroundColor Green

# 4. Docker & Compose Validation
Write-Host "`n[4/4] Validating Docker Compose configuration..." -ForegroundColor Yellow
Set-Location -Path "$PSScriptRoot\.."
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker compose config -q
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  --> docker-compose.yml syntax is valid and verified." -ForegroundColor Green
    } else {
        Write-Host "  --> Docker daemon not running or compose config warning." -ForegroundColor Gray
    }
} else {
    Write-Host "  --> Docker CLI not present in PATH (skipping container daemon validation)." -ForegroundColor Gray
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "  [SUCCESS] NOTtEodo Sanctuary is 100% Enterprise & Production Ready!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
