# ============================================================================
# BUILD-ADSOLUSOL.ps1
# Compilacion Release + Frontend + Publish
# ============================================================================

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL - BUILD RELEASE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# --- VALIDACION DE EJECUCION ---
if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Get-Location).Path
    Write-Host "[INFO] `$PSScriptRoot no detectado (ejecucion interactiva). Usando directorio actual: $Root" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 1. RUTAS
# ---------------------------------------------------------------------------

$Solution = Join-Path $Root "ADSOLUSOL.sln"
$DesktopProject = Join-Path $Root "src\ADSOLUSOL.Presentation.Desktop\ADSOLUSOL.Presentation.Desktop.csproj"
$FinalBuild = Join-Path $Root "BUILD\ADSOLUSOL"

# ---------------------------------------------------------------------------
# 2. VALIDACIONES
# ---------------------------------------------------------------------------

if (-not (Test-Path $Root)) {
    Write-Host "[FAIL] No existe la raiz:" -ForegroundColor Red
    Write-Host $Root -ForegroundColor Red
    exit 1
}

Set-Location $Root

if (-not (Test-Path $Solution)) {
    Write-Host "[FAIL] No existe ADSOLUSOL.sln" -ForegroundColor Red
    exit 1
}

$Dotnet = Get-Command dotnet -ErrorAction SilentlyContinue

if (-not $Dotnet) {
    Write-Host "[FAIL] dotnet no esta disponible." -ForegroundColor Red
    exit 1
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
Write-Host " [1/3] RESTORE" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

& dotnet restore $Solution

$RestoreCode = $LASTEXITCODE

if ($RestoreCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] RESTORE FALLO. Exit Code: $RestoreCode" -ForegroundColor Red
    exit 1
}

Write-Host "[PASS] Restore" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 4. BUILD .NET
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [2/3] BUILD .NET RELEASE" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

& dotnet build $Solution -c Release --no-restore --nologo
$BuildCode = $LASTEXITCODE

if ($BuildCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] BUILD FALLO. Exit Code: $BuildCode" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[PASS] Solucion .NET compilada." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 7. PUBLISH
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [3/3] PUBLISH" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

if (Test-Path $FinalBuild) {
    Write-Host "[INFO] Limpiando artefacto anterior..." -ForegroundColor Gray
    Remove-Item $FinalBuild -Recurse -Force
}

New-Item -ItemType Directory -Path $FinalBuild -Force | Out-Null

$publishArgs = @(
    "publish",
    $DesktopProject,
    "-c", "Release",
    "-f", "net8.0-windows10.0.19041.0",
    "-r", "win-x64",
    "--no-restore",
    "--nologo",
    "-p:WindowsPackageType=None",
    "-p:AppxPackage=false",
    "-p:GenerateAppxPackageOnBuild=false",
    "-p:WindowsAppSDKSelfContained=false",
    "-p:IgnoreMissingWorkloads=true",
    "-o", $FinalBuild
)
& dotnet @publishArgs

$PublishCode = $LASTEXITCODE

if ($PublishCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] PUBLISH FALLO. Exit Code: $PublishCode" -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------------------
# 8. VERIFICACION ARTEFACTO
# ---------------------------------------------------------------------------

$PublishedExe = Get-ChildItem -Path $FinalBuild -Filter "ADSOLUSOL.Presentation.Desktop.exe" -Recurse |
    Select-Object -ExpandProperty FullName -First 1

if ([string]::IsNullOrWhiteSpace($PublishedExe) -or (-not (Test-Path $PublishedExe))) {
    $missingName = "ADSOLUSOL.Presentation.Desktop.exe"
    if (-not [string]::IsNullOrWhiteSpace($PublishedExe)) {
        $missingName = Split-Path $PublishedExe -Leaf
    }
    Write-Host ""
    Write-Host "[FAIL] Publish termino pero falta el ejecutable principal: $missingName" -ForegroundColor Red
    exit 1
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