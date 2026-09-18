[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL - DIAGNÓSTICO Y CHEQUEO DE SALUD (HEALTH CHECK)" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

$healthFailed = $false
$baseUrl = "http://localhost:5000"

# 1. Verificación del Entorno .NET
Write-Host "`n>>> [1/4] Verificando Entorno .NET..." -ForegroundColor Yellow
$dotnetExe = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source
if (-not $dotnetExe) {
    Write-Host " [FAIL] .NET SDK no instalado o no presente en PATH." -ForegroundColor Red
    $healthFailed =$true
} else {
    $dotnetVer = &$dotnetExe --version
    Write-Host " [OK] .NET SDK $dotnetVer detectado ($dotnetExe)." -ForegroundColor Green
}

# 2. Verificación de Archivos y Base de Datos SQLite
Write-Host "`n>>> [2/4] Verificando Persistencia de Base de Datos..." -ForegroundColor Yellow
$dbPaths = @(
    (Join-Path $Root "src\ADSOLUSOL.Presentation.Api\App_Data\adsolusol.db"),
    (Join-Path $Root "App_Data\adsolusol.db")
)

$dbFound = $false
foreach ($db in $dbPaths) {
    if (Test-Path $db) {
        $dbSize = (Get-Item $db).Length / 1KB
        Write-Host (" [OK] Base de datos SQLite encontrada: {0} ({1:N2} KB)" -f $db, $dbSize) -ForegroundColor Green
        $dbFound = $true
    }
}

if (-not $dbFound) {
    Write-Host " [INFO] No se localizó base de datos SQLite física (se creará automáticamente al iniciar la API)." -ForegroundColor Gray
}

# 3. Verificación de Compilación de la Solución
Write-Host "`n>>> [3/4] Verificando Integridad del Código (Build Check)..." -ForegroundColor Yellow
$slnPath = Join-Path $Root "ADSOLUSOL.sln"

if (Test-Path $slnPath) {$buildOut = & $dotnetExe build $slnPath --nologo --verbosity quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK] La solución compila limpiamente (0 Errores)." -ForegroundColor Green
    } else {
        Write-Host " [FAIL] Se detectaron errores de compilación en la solución." -ForegroundColor Red
        $healthFailed =$true
    }
} else {
    Write-Host " [FAIL] No se encontró ADSOLUSOL.sln en la raíz." -ForegroundColor Red
    $healthFailed =$true
}

# 4. Verificación de Endpoints HTTP (Si la API está corriendo)
Write-Host "`n>>> [4/4] Verificando Estado HTTP de la API (localhost:5000)..." -ForegroundColor Yellow
try {
    $healthResp = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host " [OK] API activa en $baseUrl" -ForegroundColor Green
    Write-Host " [OK] Endpoint /health responde correctamente." -ForegroundColor Green
} catch {
    Write-Host " [INFO] La API no está en ejecución actualmente en $baseUrl." -ForegroundColor Gray
    Write-Host "       (Puedes levantarla con: powershell -ExecutionPolicy Bypass -File .\Start-Dev.ps1)" -ForegroundColor Gray
}

# Reporte Final
Write-Host "`n==============================================================================" -ForegroundColor Cyan
Write-Host " RESULTADO DEL DIAGNÓSTICO DE SALUD" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

if ($healthFailed) {
    Write-Host " [FAIL] ESTADO DE SALUD: CON ADVERTENCIAS / ERRORES" -ForegroundColor Red
} else {
    Write-Host " [PASS] ESTADO DE SALUD: EXCELENTE (SISTEMA SALUDABLE)" -ForegroundColor Green
}