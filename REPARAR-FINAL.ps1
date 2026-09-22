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

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " REPARACIÓN AUTOMÁTICA DE ADSOLUSOL.Presentation.Api" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Eliminar MauiProgram.cs duplicado/erróneo dentro del proyecto API
$strayMauiProgram = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\MauiProgram.cs"
if (Test-Path $strayMauiProgram) {
    Remove-Item $strayMauiProgram -Force
    Write-Host "[FIX] Eliminado 'MauiProgram.cs' fuera de lugar en Presentation.Api." -ForegroundColor Green
}

$strayMauiProgramRepo = Join-Path $Root "src\ADSOLUSOL.Infrastructure\Repositories\MauiProgram.cs"
if (Test-Path $strayMauiProgramRepo) {
    Remove-Item $strayMauiProgramRepo -Force
    Write-Host "[FIX] Eliminado 'MauiProgram.cs' fuera de lugar en Infrastructure/Repositories." -ForegroundColor Green
}

# 2. Corregir namespace 'Authentication' a 'Security' o 'Cryptography' en Program.cs
$programCs = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\Program.cs"
if (Test-Path $programCs) {
    $content = Get-Content $programCs -Raw
    $updated = $content -replace "using ADSOLUSOL\.Infrastructure\.Authentication;", "using ADSOLUSOL.Infrastructure.Security;"
    $updated = $updated -replace "using ADSOLUSOL\.Infrastructure\.Cryptography;", "using ADSOLUSOL.Infrastructure.Security;"
    Set-Content -Path $programCs -Value $updated -Encoding UTF8
    Write-Host "[FIX] Corregido namespace de infraestructura en 'Program.cs'." -ForegroundColor Green
}

# 3. Corregir imports inexistentes en Routes.razor
$routesRazor = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\Routes.razor"
if (Test-Path $routesRazor) {
    $content = Get-Content $routesRazor -Raw
    $updated = $content -replace "@using ADSOLUSOL\.Presentation\.Shared;?", ""
    Set-Content -Path $routesRazor -Value $updated -Encoding UTF8
    Write-Host "[FIX] Removido namespace inexistente 'Shared' en 'Routes.razor'." -ForegroundColor Green
}

# 4. Asegurar usings de Blazor en _Imports.razor dentro de Presentation.Api
$importsRazor = Join-Path $Root "src\ADSOLUSOL.Presentation.Api\_Imports.razor"
$importsContent = @"
@using System.Net.Http
@using Microsoft.AspNetCore.Components.Forms
@using Microsoft.AspNetCore.Components.Routing
@using Microsoft.AspNetCore.Components.Web
@using Microsoft.AspNetCore.Components.Web.Virtualization
@using Microsoft.JSInterop
"@
Set-Content -Path $importsRazor -Value $importsContent -Encoding UTF8
Write-Host "[FIX] Actualizado '_Imports.razor' con los namespaces de Blazor requeridos." -ForegroundColor Green

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " REPARACIÓN COMPLETADA. Ejecutando BUILD-ADSOLUSOL.ps1..." -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""

Set-Location $Root
& ".\BUILD-ADSOLUSOL.ps1"