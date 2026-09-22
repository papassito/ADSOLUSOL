[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🔍 DIAGNÓSTICO PROFUNDO DE ERRORES DE COMPILACIÓN" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$sln = Get-ChildItem -Path $Root -Filter "*.sln" -Recurse | Select-Object -First 1

if (-not $sln) {
    Write-Host "[CRÍTICO] No se encontró el archivo .sln en la ruta $Root" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Analizando compilación en: $($sln.FullName)`n" -ForegroundColor Gray

# Ejecutar compilación y capturar tanto salida estándar como errores de flujo
$rawOutput = & dotnet build "$($sln.FullName)" -v:normal /noconlog 2>&1

$exitCode = $LASTEXITCODE

# 1. Captura de errores C# estándar (CSxxxx), MSBuild (MSBxxxx) y NuGet (NUxxxx)
$structuredErrors = @($rawOutput | Where-Object { 
    $_ -match ':\s*error\s+(CS|MSB|NU)\d+:' -or $_ -match 'error\s+CS\d+:'
})

# 2. Captura de fallos generales de proyecto o configuración
$generalErrors = @($rawOutput | Where-Object { 
    $_ -match 'ERROR' -or $_ -match 'El proyecto.*no se pudo' -or $_ -match 'falló'
})

if ($exitCode -eq 0) {
    Write-Host "[✓] La compilación completó sin errores (Exit Code 0)." -ForegroundColor Green
    exit 0
}

Write-Host "==========================================================================" -ForegroundColor Red
Write-Host " ❌ RESUMEN DE ERRORES ENCONTRADOS (Exit Code: $exitCode)" -ForegroundColor Red
Write-Host "==========================================================================" -ForegroundColor Red
Write-Host ""

if ($structuredErrors.Count -gt 0) {
    Write-Host "📌 ERRORES DE CÓDIGO Y DEPENDENCIAS:" -ForegroundColor Yellow
    foreach ($err in $structuredErrors) {
        Write-Host "  -> $($err.ToString().Trim())" -ForegroundColor Red
    }
    Write-Host ""
}

if ($structuredErrors.Count -eq 0 -and $generalErrors.Count -gt 0) {
    Write-Host "📌 ERRORES GENERALES / CONFIGURACIÓN DE PROYECTO:" -ForegroundColor Yellow
    foreach ($err in $generalErrors) {
        Write-Host "  -> $($err.ToString().Trim())" -ForegroundColor Red
    }
    Write-Host ""
}

if ($structuredErrors.Count -eq 0 -and $generalErrors.Count -eq 0) {
    Write-Host "📌 SALIDA CRUDA DEL COMPILADOR (ÚLTIMAS 35 LÍNEAS):" -ForegroundColor Yellow
    $rawOutput | Select-Object -Last 35 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan