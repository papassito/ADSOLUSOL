# ============================================================================
# BUILD-ADSOLUSOL.ps1
# Compilación Release + Frontend + Publish
# ============================================================================

[CmdletBinding()]
param(
    [string]$Root = "Y:\Documentos\GitHub\ADSOLUSOL"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$BuildFailed = $false

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL - BUILD RELEASE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# 1. RUTAS
# ---------------------------------------------------------------------------

$Solution = Join-Path $Root "ADSOLUSOL.sln"

$DesktopProject = Join-Path `
    $Root `
    "src\ADSOLUSOL.Presentation.Desktop\ADSOLUSOL.Presentation.Desktop.csproj"

$FinalBuild = Join-Path `
    $Root `
    "BUILD\ADSOLUSOL"

# ---------------------------------------------------------------------------
# 2. VALIDACIONES
# ---------------------------------------------------------------------------

if (-not (Test-Path $Root)) {
    Write-Host "[FAIL] No existe la raíz:" -ForegroundColor Red
    Write-Host $Root -ForegroundColor Red
    return
}

Set-Location $Root

if (-not (Test-Path $Solution)) {
    Write-Host "[FAIL] No existe ADSOLUSOL.sln" -ForegroundColor Red
    return
}

$Dotnet = Get-Command dotnet -ErrorAction SilentlyContinue

if (-not $Dotnet) {
    Write-Host "[FAIL] dotnet no está disponible." -ForegroundColor Red
    return
}

Write-Host "[OK] Root: $Root" -ForegroundColor Green
Write-Host "[OK] .NET: $($Dotnet.Source)" -ForegroundColor Green

$DotnetVersion = & dotnet --version

Write-Host "[OK] SDK: $DotnetVersion" -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------------------------
# 3. RESTORE
# ---------------------------------------------------------------------------

Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [1/5] RESTORE" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

& dotnet restore $Solution

$RestoreCode = $LASTEXITCODE

if ($RestoreCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] RESTORE FALLÓ. Exit Code: $RestoreCode" -ForegroundColor Red
    return
}

Write-Host "[PASS] Restore" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 4. BUILD .NET
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [2/5] BUILD .NET RELEASE" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

& dotnet build `
    $Solution `
    -c Release `
    --no-restore `
    --nologo

$BuildCode = $LASTEXITCODE

if ($BuildCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] BUILD FALLÓ. Exit Code: $BuildCode" -ForegroundColor Red
    return
}

Write-Host ""
Write-Host "[PASS] Solución .NET compilada." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 7. PUBLISH
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [5/5] PUBLISH" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

if (Test-Path $FinalBuild) {
    Write-Host "[INFO] Limpiando artefacto anterior..." -ForegroundColor Gray

    Remove-Item `
        $FinalBuild `
        -Recurse `
        -Force
}

New-Item `
    -ItemType Directory `
    -Path $FinalBuild `
    -Force |
    Out-Null

& dotnet publish `
    $DesktopProject `
    -c Release `
    --no-restore `
    --nologo `
    -o $FinalBuild

$PublishCode = $LASTEXITCODE

if ($PublishCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] PUBLISH FALLÓ. Exit Code: $PublishCode" -ForegroundColor Red
    return
}

# ---------------------------------------------------------------------------
# 8. VERIFICACIÓN ARTEFACTO
# ---------------------------------------------------------------------------

$PublishedExe = Join-Path `
    $FinalBuild `
    "ADSOLUSOL.Presentation.Desktop.exe"

if (-not (Test-Path $PublishedExe)) {
    Write-Host ""
    Write-Host "[FAIL] Publish terminó pero falta el ejecutable principal: $(Split-Path $PublishedExe -Leaf)" -ForegroundColor Red
    return
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " ADSOLUSOL - BUILD COMPLETADO" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "RESTORE  : PASS" -ForegroundColor Green
Write-Host "BUILD    : PASS" -ForegroundColor Green

Write-Host "PUBLISH  : PASS" -ForegroundColor Green
Write-Host ""
Write-Host "ARTEFACTO FINAL:" -ForegroundColor Cyan
Write-Host $FinalBuild -ForegroundColor White
Write-Host ""
Write-Host "EJECUTABLE NATIVO:" -ForegroundColor Cyan
Write-Host $PublishedExe -ForegroundColor White
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green