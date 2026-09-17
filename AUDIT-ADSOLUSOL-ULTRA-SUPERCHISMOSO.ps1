$ErrorActionPreference = "Continue"
$Root = $PSScriptRoot
if (-not $Root) { $Root = (Get-Location).Path }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL — AUDITORÍA Y CERTIFICACIÓN " -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

$slnPath = Join-Path $Root "ADSOLUSOL.sln"
$dotnetExe = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source

if (-not $dotnetExe) {
    Write-Host "[CRITICAL] dotnet no encontrado en PATH." -ForegroundColor Red
    exit 1
}

Write-Host "`n>>> Compilando la solución..." -ForegroundColor Yellow
$buildOut = & $dotnetExe build $slnPath --nologo 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[PASS] Compilación exitosa (0 Errores)." -ForegroundColor Green
    Write-Host "`nGATE RESULT: PASS" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Errores de compilación detectados:" -ForegroundColor Red
    Write-Host $buildOut
    Write-Host "`nGATE RESULT: FAIL" -ForegroundColor Red
    exit 1
}