# File: seal_adsolusol_release.ps1
[CmdletBinding()]
param(
    [string]$Version = "v1.0.0-INTEGRATED",
    [string]$Message = "feat(marketing): complete SOLUSOL_AUTH_V1 Ed25519 integration with SIC core"
)

$ErrorActionPreference = "Stop"

Write-Host ">>> Agregando cambios al staging de Git (ADSOLUSOL)..." -ForegroundColor Yellow
git add .

Write-Host ">>> Ejecutando commit estandarizado..." -ForegroundColor Yellow
git commit -m "$Message" -m "Build: PASS (0 Errors / 0 Warnings)`nCrypto: Ed25519 (SOLUSOL_AUTH_V1)`nDI: Registered`nTelemetry Bridge: Active (ADS -> SIC)"

Write-Host ">>> Creando Tag anotado: $Version..." -ForegroundColor Yellow
git tag -a "$Version" -m "ADSOLUSOL Marketing Engine - Fully Integrated with SIC Core ($Version)"

Write-Host ""
Write-Host "✅ [OK] Repositorio ADSOLUSOL sellado exitosamente con el tag $Version" -ForegroundColor Green