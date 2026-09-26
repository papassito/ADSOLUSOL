# ==============================================================================
# REPARAR-FINAL.ps1
# Corrige los errores de archivos fuera de lugar y namespaces en Presentation.Api
# ==============================================================================

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Get-Location).Path
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " REPARACION AUTOMATICA DE ADSOLUSOL.Presentation.Api" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Eliminar MauiProgram.cs duplicado/erroneo dentro del proyecto API
$strayMauiProgram = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\MauiProgram.cs"
if (Test-Path -LiteralPath $strayMauiProgram) {
    Remove-Item -LiteralPath $strayMauiProgram -Force
    Write-Host "[FIX] Eliminado 'MauiProgram.cs' fuera de lugar en Presentation.Api." -ForegroundColor Green
}

$strayMauiProgramInfra = Join-Path $Root "src\ADSOLUSOL.Infrastructure\MauiProgram.cs"
if (Test-Path -LiteralPath $strayMauiProgramInfra) {
    Remove-Item -LiteralPath $strayMauiProgramInfra -Force
    Write-Host "[FIX] Eliminado 'MauiProgram.cs' fuera de lugar en Infrastructure." -ForegroundColor Green
}

$strayMauiProgramRepo = Join-Path $Root "src\ADSOLUSOL.Infrastructure\Repositories\MauiProgram.cs"
if (Test-Path -LiteralPath $strayMauiProgramRepo) {
    Remove-Item -LiteralPath $strayMauiProgramRepo -Force
    Write-Host "[FIX] Eliminado 'MauiProgram.cs' fuera de lugar en Infrastructure/Repositories." -ForegroundColor Green
}

# 1.1 Extirpar los archivos fuente vacios (0 bytes) y esqueletos no deseados
$emptyFiles = Get-ChildItem -Path (Join-Path $Root "src") -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -eq 0 -and $_.Name -ne ".gitkeep" -and $_.FullName -notmatch '\\/[\\/]' }
foreach ($ef in $emptyFiles) {
    Remove-Item -Path $ef.FullName -Force -ErrorAction SilentlyContinue
    $relEmpty = $ef.FullName.Replace($Root, "")
    Write-Host "[FIX] Archivo vacio eliminado: $relEmpty" -ForegroundColor Green
}

# 1.1b Extirpar archivos markdown vacios (0 bytes) en docs/
$emptyDocs = Get-ChildItem -Path (Join-Path $Root "docs") -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -eq 0 }
foreach ($ed in $emptyDocs) {
    Remove-Item -Path $ed.FullName -Force -ErrorAction SilentlyContinue
    Write-Host "[FIX] Archivo markdown vacio eliminado: $($ed.Name)" -ForegroundColor Green
}

# 1.2 Extirpar archivos legados y plantillas vacias
$legacyMarketingApi = Join-Path $Root "src\ADSOLUSOL.Infrastructure\ExternalServices\MarketingApi"
if (Test-Path $legacyMarketingApi) {
    Remove-Item -Path $legacyMarketingApi -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[FIX] Carpeta y cliente legado MarketingApi eliminados." -ForegroundColor Green
}

$dummyArchTest = Join-Path $Root "tests\ADSOLUSOL.ArchitectureTests\UnitTest1.cs"
if (Test-Path $dummyArchTest) {
    Remove-Item -Path $dummyArchTest -Force -ErrorAction SilentlyContinue
    Write-Host "[FIX] UnitTest1.cs de plantilla eliminado de ArchitectureTests." -ForegroundColor Green
}

$duplicateApiSeal = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\DOCUMENTATION_SEAL.json"
if (Test-Path $duplicateApiSeal) {
    Remove-Item -Path $duplicateApiSeal -Force -ErrorAction SilentlyContinue
    Write-Host "[FIX] Sello duplicado en Presentation.Api eliminado." -ForegroundColor Green
}

# 2. Corregir namespace 'Authentication' a 'Security' o 'Cryptography' en Program.cs
$programCs = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\Program.cs"
if (Test-Path $programCs) {
    $content = [System.IO.File]::ReadAllText($programCs, [System.Text.Encoding]::UTF8)
    if ($content -match 'ADSOLUSOL\.Infrastructure\.(Authentication|Cryptography)') {
        $updated = $content.Replace('using ADSOLUSOL.Infrastructure.Authentication;', 'using ADSOLUSOL.Infrastructure.Security;')
        $updated = $updated.Replace('using ADSOLUSOL.Infrastructure.Cryptography;', 'using ADSOLUSOL.Infrastructure.Security;')
        [System.IO.File]::WriteAllText($programCs, $updated, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "[FIX] Namespace corregido en Program.cs." -ForegroundColor Green
    }
}

# 3. Corregir imports inexistentes en Routes.razor
$routesRazor = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\Routes.razor"
if (Test-Path $routesRazor) {
    $content = Get-Content $routesRazor -Raw
    $updated = $content.Replace('@using ADSOLUSOL.Presentation.Shared;', '').Replace('@using ADSOLUSOL.Presentation.Shared', '')
    [System.IO.File]::WriteAllText($routesRazor, $updated, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "[FIX] Removido namespace inexistente 'Shared' en 'Routes.razor'." -ForegroundColor Green
}

# 4. Asegurar usings de Blazor en _Imports.razor dentro de Presentation.Api
$importsRazor = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\_Imports.razor"
$importsContent = @(
    '@using System.Net.Http',
    '@using Microsoft.AspNetCore.Components.Forms',
    '@using Microsoft.AspNetCore.Components.Routing',
    '@using Microsoft.AspNetCore.Components.Web',
    '@using Microsoft.AspNetCore.Components.Web.Virtualization',
    '@using Microsoft.JSInterop'
) -join "`r`n"
[System.IO.File]::WriteAllText($importsRazor, $importsContent, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "[FIX] Actualizado '_Imports.razor' con los namespaces de Blazor requeridos." -ForegroundColor Green

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " REPARACION COMPLETADA. Ejecutando BUILD-ADSOLUSOL.ps1..." -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

Set-Location $Root
$buildScript = Join-Path $Root "BUILD-ADSOLUSOL.ps1"
if (Test-Path $buildScript) {
    & $buildScript
} else {
    Write-Host "[WARN] No se encontro 'BUILD-ADSOLUSOL.ps1' en la raiz. Omitiendo compilacion final." -ForegroundColor Yellow
}