# AUDIT-SOPA-COMPLETA.ps1
# Diagnóstico Forense y Extracción de Errores Crudos de .NET (ZERO PARCHES)

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🕵️‍♂️ DIAGNÓSTICO FORENSE ULTRA-COMPLETO — 'SACANDO TODA LA SOPA'" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "[INFO] Inspeccionando raíz: $Root`n" -ForegroundColor Gray

# ------------------------------------------------------------------------------
# 1. LOCALIZADOR ROBUSTO DEL SDK DE .NET
# ------------------------------------------------------------------------------
$dotnetExe = $null

$candidatePaths = @(
    "C:\Users\Radio 2027\Documents\Codex\tools\dotnet\dotnet.exe",
    "C:\Program Files\dotnet\dotnet.exe",
    "C:\Program Files (x86)\dotnet\dotnet.exe"
)

foreach ($path in $candidatePaths) {
    if (Test-Path $path) {
        $dotnetExe = $path
        break
    }
}

if (-not $dotnetExe) {
    $dotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
    if ($dotnetCmd) { $dotnetExe = $dotnetCmd.Source }
}

if (-not $dotnetExe -or -not (Test-Path $dotnetExe)) {
    Write-Host "[CRITICAL] No se localizó ningún ejecutable 'dotnet.exe' en el sistema." -ForegroundColor Red
    exit 1
}

Write-Host "[✓] Ejecutable .NET detectado: $dotnetExe" -ForegroundColor Green
$sdkVer = (& $dotnetExe --version 2>&1).ToString().Trim()
Write-Host "[✓] Versión de SDK en uso    : $sdkVer`n" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 2. LOCALIZACIÓN DE PROYECTOS Y SOLUCIÓN
# ------------------------------------------------------------------------------
$slnPath = Get-ChildItem -Path $Root -Filter "*.sln" -Recurse | Select-Object -First 1
if (-not $slnPath) {
    Write-Host "[CRITICAL] No se encontró ningún archivo .sln en la ruta actual." -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Solución bajo análisis: $($slnPath.FullName)" -ForegroundColor Yellow

# ------------------------------------------------------------------------------
# 3. EXTRAER SOPA DE COMPILACIÓN (BUILD ERRORS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> [FASE 1] Ejecutando 'dotnet build' para capturar errores de C#..." -ForegroundColor Yellow

$buildLog = Join-Path $Root "_audit_build_raw.log"
& $dotnetExe build "$($slnPath.FullName)" -v:normal /noconlog > $buildLog 2>&1

$rawBuildOutput = Get-Content $buildLog -Encoding UTF8 -ErrorAction SilentlyContinue
Remove-Item $buildLog -Force -ErrorAction SilentlyContinue

$csErrors = $rawBuildOutput | Select-String -Pattern "error CS\d+", "error MSB\d+", "Fatal error"

if ($csErrors) {
    Write-Host "`n==========================================================================" -ForegroundColor Red
    Write-Host " 🔴 ERRORES CRÍTICOS DE COMPILACIÓN DETECTADOS ($($csErrors.Count))" -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Red
    foreach ($err in $csErrors) {
        Write-Host "  ├── $err" -ForegroundColor Red
    }
} else {
    Write-Host "[✓] La solución compila limpio sin errores de MSBuild ni C#." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 4. EXTRAER SOPA DE PRUEBAS (TEST FAILURES)
# ------------------------------------------------------------------------------
Write-Host "`n>>> [FASE 2] Buscando y ejecutando proyectos de pruebas..." -ForegroundColor Yellow

$testProjects = Get-ChildItem -Path $Root -Filter "*Test*.csproj" -Recurse

if (-not $testProjects) {
    Write-Host "[WARNING] No se localizaron archivos .csproj con el patrón '*Test*'." -ForegroundColor Yellow
} else {
    foreach ($testProj in $testProjects) {
        Write-Host "`n📌 Ejecutando Suite: $($testProj.Name)" -ForegroundColor Cyan
        $testLog = Join-Path $Root "_audit_test_raw.log"
        
        & $dotnetExe test "$($testProj.FullName)" --no-build -v:normal > $testLog 2>&1
        $rawTestOutput = Get-Content $testLog -Encoding UTF8 -ErrorAction SilentlyContinue
        Remove-Item $testLog -Force -ErrorAction SilentlyContinue

        $failedTests = $rawTestOutput | Select-String -Pattern "Failed", "Error Message:", "Stack Trace:"

        if ($failedTests) {
            Write-Host "  🔴 DETALLES DE PRUEBAS FALLIDAS:" -ForegroundColor Red
            $rawTestOutput | ForEach-Object {
                if ($_ -match "Failed|Error|Exception|Assert") {
                    Write-Host "     $_" -ForegroundColor Red
                } elseif ($_ -match "Passed") {
                    Write-Host "     $_" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  [✓] Pruebas ejecutadas correctamente." -ForegroundColor Green
        }
    }
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host " FIN DE DIAGNÓSTICO (ZERO CÓDIGO ALTERADO)" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan