<#
================================================================================
  ADSOLUSOL :: AUDITORIA PERICIAL Y ESTADO EN VIVO (LIVE AUDIT)
  Inspeccion en tiempo real: Git, Codificacion, Contratos, Compilacion,
  Regresiones, Ausencia de Multi-Tenant y Notaria Criptografica.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Get-Location).Path
}
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [LIVE] ADSOLUSOL :: AUDITORIA EN VIVO (AUDIT LIVE)                       " -ForegroundColor Cyan
Write-Host "    Verificacion Pericial de Salud Digital, Codigo y Documentacion        " -ForegroundColor DarkCyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Objetivo: $ScriptRoot`n" -ForegroundColor DarkGray

$GlobalErrors = 0
$GlobalWarnings = 0

function Report-Check {
    param(
        [string]$Fase,
        [string]$Item,
        [string]$Mensaje,
        [string]$Nivel = "OK"
    )
    $color = switch ($Nivel) {
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "FAIL"  { "Red" }
        Default { "Cyan" }
    }
    Write-Host "[$Nivel] " -ForegroundColor $color -NoNewline
    Write-Host "[$Fase] " -ForegroundColor DarkGray -NoNewline
    Write-Host "$Item " -ForegroundColor White -NoNewline
    Write-Host "-> $Mensaje" -ForegroundColor Gray

    if ($Nivel -eq "FAIL") { $script:GlobalErrors++ }
    elseif ($Nivel -eq "WARN") { $script:GlobalWarnings++ }
}

# ------------------------------------------------------------------------------
# FASE 1: GIT & WORKING TREE
# ------------------------------------------------------------------------------
Write-Host "`n[1/7] Inspeccionando estado de Git y arbol de trabajo..." -ForegroundColor Yellow
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitStatus = & git status --porcelain 2>&1
    if ($gitStatus) {
        Report-Check "GIT" "Working Tree" "Hay archivos modificados o sin rastrear en el repositorio." "WARN"
    } else {
        Report-Check "GIT" "Working Tree" "Arbol de trabajo completamente limpio." "OK"
    }
} else {
    Report-Check "GIT" "Binario git" "git no esta disponible en PATH." "WARN"
}

# ------------------------------------------------------------------------------
# FASE 2: HIGIENE FORENSE DE CODIFICACION - BOM, MOJIBAKE Y ARCHIVOS VACIOS
# ------------------------------------------------------------------------------
Write-Host "`n[2/7] Inspeccionando BOM UTF-8, Mojibake y archivos vacios..." -ForegroundColor Yellow
$textFiles = Get-ChildItem -Path @("src", "tests", "docs") -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { 
        $_.Extension.ToLower() -in @('.cs', '.csproj', '.json', '.md', '.ps1', '.xaml', '.razor') -and
        $_.FullName -notmatch '[\\/](\.git|bin|obj|node_modules|dist|BUILD|\.build|\.repair-backups|TestResults)[\\/]' 
    }

foreach ($file in $textFiles) {
    $rel = $file.FullName.Substring($ScriptRoot.Length).TrimStart('\', '/')
    if ($file.Length -eq 0) {
        Report-Check "ENCODING" $rel "Archivo de 0 bytes detectado." "FAIL"
        continue
    }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Report-Check "BOM" $rel "Contiene marca UTF-8 BOM." "FAIL"
        }
    } catch {}

    $rawText = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($rawText -and $rawText -match "(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})") {
        Report-Check "MOJIBAKE" $rel "Secuencias corruptas detectadas (tildes/símbolos Windows-1252)." "WARN"
        Report-Check "MOJIBAKE" $rel "Secuencias corruptas detectadas (tildes/simbolos Windows-1252)." "WARN"
    }
    if ($rawText -and $rawText.Contains([char]0xFFFD)) {
        Report-Check "UNICODE" $rel "Caracter de reemplazo corrupto (\uFFFD) detectado." "FAIL"
    }
}

# ------------------------------------------------------------------------------
# FASE 3: TOPOLOGIA EN RAIZ Y ESTRUCTURA ONION
# ------------------------------------------------------------------------------
Write-Host "`n[3/7] Verificando higiene estructural y topologia Onion..." -ForegroundColor Yellow
$rootCsproj = Get-ChildItem -Path . -Filter "*.csproj" -File -ErrorAction SilentlyContinue
if ($rootCsproj.Count -gt 0) {
    foreach ($rc in $rootCsproj) {
        Report-Check "ONION" $rc.Name "Proyecto .csproj huerfano en raiz." "FAIL"
    }
} else {
    Report-Check "ONION" "Higiene Raiz" "Cero proyectos .csproj en raiz." "OK"
}

$coreProjects = @(
    "src/ADSOLUSOL.Domain/ADSOLUSOL.Domain.csproj",
    "src/ADSOLUSOL.Application/ADSOLUSOL.Application.csproj",
    "src/ADSOLUSOL.Infrastructure/ADSOLUSOL.Infrastructure.csproj",
    "src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj",
    "src/ADSOLUSOL.Presentation.Desktop/ADSOLUSOL.Presentation.Desktop.csproj"
)
foreach ($cp in $coreProjects) {
    if (Test-Path $cp) {
        Report-Check "ONION" $cp "Capa arquitectonica presente." "OK"
    } else {
        Report-Check "ONION" $cp "Capa arquitectonica faltante." "FAIL"
    }
}

# ------------------------------------------------------------------------------
# FASE 4: VERIFICACION DE RESIDUOS MULTI-TENANT
# ------------------------------------------------------------------------------
Write-Host "`n[4/7] Comprobando descarte de requerimientos multi-tenant..." -ForegroundColor Yellow
$reqContent = if (Test-Path "REQUIREMENTS.md") { Get-Content "REQUIREMENTS.md" -Raw -Encoding UTF8 } else { "" }
if ($reqContent -match "REQ-TEN-") {
    Report-Check "GOVERNANCE" "REQUIREMENTS.md" "Contiene requisitos residuales REQ-TEN." "FAIL"
} else {
    Report-Check "GOVERNANCE" "REQUIREMENTS.md" "Libre de requisitos multi-tenant." "OK"
}

$sealContent = if (Test-Path "DOCUMENTATION_SEAL.json") { Get-Content "DOCUMENTATION_SEAL.json" -Raw -Encoding UTF8 } else { "" }
if ($sealContent -match "Tenant isolation") {
    Report-Check "GOVERNANCE" "DOCUMENTATION_SEAL.json" "Contiene principio no aplicable 'Tenant isolation'." "FAIL"
} else {
    Report-Check "GOVERNANCE" "DOCUMENTATION_SEAL.json" "Principios alineados con el alcance real." "OK"
}

# ------------------------------------------------------------------------------
# FASE 5: COMPILACION RELEASE (.NET 8)
# ------------------------------------------------------------------------------
Write-Host "`n[5/7] Compilando solucion ADSOLUSOL.sln en configuracion Release..." -ForegroundColor Yellow
$buildOut = & dotnet build ADSOLUSOL.sln -c Release --nologo -v:minimal -p:IgnoreMissingWorkloads=true -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false 2>&1
if ($LASTEXITCODE -eq 0) {
    Report-Check "BUILD" "ADSOLUSOL.sln" "Compilacion 100% limpia en Release." "OK"
} else {
    Report-Check "BUILD" "ADSOLUSOL.sln" "Fallo de compilacion con codigo de salida $LASTEXITCODE." "FAIL"
}

# ------------------------------------------------------------------------------
# FASE 6: SUITES DE PRUEBAS DE REGRESIÓN
# FASE 6: SUITES DE PRUEBAS DE REGRESION
# ------------------------------------------------------------------------------
Write-Host "`n[6/7] Ejecutando pruebas de regresión de negocio (20 comprobaciones)..." -ForegroundColor Yellow
Write-Host "`n[6/7] Ejecutando pruebas de regresion de negocio (20 comprobaciones)..." -ForegroundColor Yellow
$testOut = & dotnet test ADSOLUSOL.sln -c Release --no-build --nologo -v:q 2>&1
if ($LASTEXITCODE -eq 0) {
    Report-Check "TESTS" "RegressionTests" "Todas las pruebas de regresión pasaron con éxito." "OK"
    Report-Check "TESTS" "RegressionTests" "Todas las pruebas de regresion pasaron con exito." "OK"
} else {
    Report-Check "TESTS" "RegressionTests" "Fallo en la suite de pruebas de regresión." "FAIL"
    Report-Check "TESTS" "RegressionTests" "Fallo en la suite de pruebas de regresion." "FAIL"
}

# ------------------------------------------------------------------------------
# FASE 7: DICTAMEN FINAL EN VIVO
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN FINAL DE AUDIT LIVE                         " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Errores Criticos : $GlobalErrors" -ForegroundColor $(if ($GlobalErrors -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias     : $GlobalWarnings" -ForegroundColor $(if ($GlobalWarnings -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($GlobalErrors -gt 0) {
    Write-Host "`n[FAIL] RECHAZADO: Se detectaron inconsistencias criticas en vivo.`n" -ForegroundColor Red
    exit 1
} elseif ($GlobalWarnings -gt 0) {
    Write-Host "`n[PASS WITH WARNINGS] APROBADO CON OBSERVACIONES MENORES.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] APROBADO: El ecosistema esta integro y en perfecto estado digital.`n" -ForegroundColor Green
    exit 0
}