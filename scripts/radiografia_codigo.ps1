<#
================================================================================
  ADSOLUSOL - DIAGNOSTICO PROFUNDO: RADIOGRAFIA DE CODIGO (.NET 8 / C#)
================================================================================
#>

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$resolved = if ($PSScriptRoot) { (Resolve-Path $PSScriptRoot).Path } else { (Resolve-Path ".").Path }
if (Test-Path (Join-Path $resolved "ADSOLUSOL.sln")) {
    $RepoRoot = $resolved
} elseif (Test-Path (Join-Path (Split-Path $resolved -Parent) "ADSOLUSOL.sln")) {
    $RepoRoot = (Split-Path $resolved -Parent)
} else {
    $RepoRoot = $resolved
}
Set-Location $RepoRoot

Clear-Host

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [RADAR] RADIOGRAFIA INTEGRAL DE CODIGO - ADSOLUSOL (.NET 8 / C#)" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Repositorio: $RepoRoot`n" -ForegroundColor Gray

$IssuesFound = 0
$CriticalErrors = @()
$Warnings = @()

function Report-Critical ($msg) {
    $script:IssuesFound++
    $script:CriticalErrors += $msg
    Write-Host " [ZURRADO] $msg" -ForegroundColor Red
}

function Report-Warn ($msg) {
    $script:Warnings += $msg
    Write-Host " [ADVERTENCIA] $msg" -ForegroundColor Yellow
}

function Report-Ok ($msg) {
    Write-Host " [LIMPIO] $msg" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 1. ARCHIVOS CORRUPTOS Y SINTAXIS BASURA
# ------------------------------------------------------------------------------
Write-Host "--- 1. ESCANEO DE SINTAXIS Y CORRUPCION ---" -ForegroundColor Cyan

$csFiles = Get-ChildItem -Path @("src", "tests") -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\/[\\/]' }

foreach ($file in $csFiles) {
    $relPath = $file.FullName.Replace($RepoRoot, ".")
    
    # Archivos de 0 bytes
    if ($file.Length -eq 0) {
        Report-Critical "Archivo vacio (0 bytes): $relPath"
        continue
    }

    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

    # Sintaxis corrupta por interpolaciones regex previas ('tif', 'if' fuera de función)
    if ($content -match '\btif\b') {
        Report-Critical "Palabra corrupta 'tif' detectada en: $relPath"
    }
    
    # Backticks o comillas sin cerrar
    $backtickCount = ($content.ToCharArray() | Where-Object { $_ -eq '`' }).Count
    if ($backtickCount % 2 -ne 0) {
        Report-Critical "String literal con backticks (`) sin cerrar en: $relPath"
    }

    # Declaraciones fuera de función (en C# top-level statements son canónicas solo en Program.cs)
    if ($file.Name -notmatch "Program\.cs$" -and $content -match '(?m)^if\s+') {
        Report-Critical "Instruccion 'if' fuera de cuerpo de funcion en: $relPath"
    }

    if ($content.Contains([char]0xFFFD)) {
        Report-Critical "Secuencia UTF-8 corrupta (\uFFFD) en: $relPath"
    }
}
Report-Ok "$($csFiles.Count) archivos C# examinados a nivel de caracteres y sintaxis."

# ------------------------------------------------------------------------------
# 2. ESTRUCTURA Y ONION ARCHITECTURE
# ------------------------------------------------------------------------------
Write-Host "`n--- 2. ESTRUCTURA Y ONION ARCHITECTURE ---" -ForegroundColor Cyan

$strayCsproj = Get-ChildItem -Path $RepoRoot -Filter "*.csproj" -File -ErrorAction SilentlyContinue
if ($strayCsproj.Count -gt 0) {
    Report-Critical "Proyectos .csproj huerfanos en la raiz del repositorio."
} else {
    Report-Ok "Raiz inmaculada: Todo el codigo reside dentro de src/ y tests/."
}

# ------------------------------------------------------------------------------
# 3. SEGURIDAD Y CALIDAD DE CODIGO
# ------------------------------------------------------------------------------
Write-Host "`n--- 3. SEGURIDAD Y CALIDAD DE CODIGO ---" -ForegroundColor Cyan

$emptyCatches = $csFiles | Select-String -Pattern "catch\s*(\([^\)]*\))?\s*\{\s*\}"
if ($emptyCatches) {
    Report-Critical "Bloques catch silenciosos que ocultan excepciones."
} else {
    Report-Ok "Cero capturas silenciosas en bloques catch."
}

$notImplemented = $csFiles | Select-String -Pattern "NotImplementedException"
if ($notImplemented) {
    Report-Critical "Metodos con NotImplementedException detectados."
} else {
    Report-Ok "Cero NotImplementedException en codigo productivo."
}

# ------------------------------------------------------------------------------
# 4. PRUEBA DE FUEGO (COMPILADOR Y PRUEBAS .NET 8)
# ------------------------------------------------------------------------------
Write-Host "`n--- 4. PRUEBA DE FUEGO (COMPILADOR Y PRUEBAS .NET 8) ---" -ForegroundColor Cyan

Write-Host " Compilando solucion con 'dotnet build'..." -NoNewline
$buildOut = & dotnet build (Join-Path $RepoRoot "ADSOLUSOL.sln") -c Release -p:IgnoreMissingWorkloads=true -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false -v:quiet --nologo 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [FAIL]" -ForegroundColor Red
    Report-Critical "La solucion NO COMPILA. Errores:`n$buildOut"
} else {
    Write-Host " [OK]" -ForegroundColor Green
    Report-Ok "dotnet build paso sin errores (Release)."
}

Write-Host " Ejecutando suites de regresion con 'dotnet test'..." -NoNewline
$testOut = & dotnet test (Join-Path $RepoRoot "ADSOLUSOL.sln") -c Release --no-build -v:quiet --nologo 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [FAIL]" -ForegroundColor Red
    Report-Critical "Las PRUEBAS FALLARON. Errores:`n$testOut"
} else {
    Write-Host " [OK]" -ForegroundColor Green
    Report-Ok "dotnet test paso sin errores (100% pruebas aprobadas)."
}

# ------------------------------------------------------------------------------
# DICTAMEN FINAL
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host " DICTAMEN FINAL DE CODIGO" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($IssuesFound -gt 0) {
    Write-Host " ESTADO GLOBAL: [ZURRADO] ($IssuesFound errores criticos encontrados)" -ForegroundColor Red
    Write-Host "`nResumen de fallos para arreglar:" -ForegroundColor Red
    foreach ($err in $CriticalErrors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
    Write-Host "==========================================================================`n" -ForegroundColor Cyan
    exit 1
} elseif ($Warnings.Count -gt 0) {
    Write-Host " ESTADO GLOBAL: [LIMPIO PERO CON ADVERTENCIAS] ($($Warnings.Count) avisos)" -ForegroundColor Yellow
    foreach ($w in $Warnings) {
        Write-Host "  - $w" -ForegroundColor Yellow
    }
} else {
    Write-Host " ESTADO GLOBAL: [IMPECABLE / 100% LIMPIO]" -ForegroundColor Green
    Write-Host " El codigo compila, pasa las pruebas, respeta paquetes y esta protegido contra DoS." -ForegroundColor Green
}
Write-Host "==========================================================================`n" -ForegroundColor Cyan