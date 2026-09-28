<#
================================================================================
  RX DISPATCH - DIAGNOSTICO PROFUNDO: RADIOGRAFIA DE CODIGO v4.2
================================================================================
#>

$resolved = (Resolve-Path ".").Path
if ((Test-Path (Join-Path $resolved "..\cmd")) -and -not (Test-Path (Join-Path $resolved "cmd"))) {
    $RepoRoot = (Resolve-Path (Join-Path $resolved "..")).Path
} else {
    $RepoRoot = $resolved
}
Set-Location $RepoRoot

$localTmp = Join-Path $RepoRoot ".tmp_build"
if (-not (Test-Path $localTmp)) {
    New-Item -ItemType Directory -Path $localTmp -Force | Out-Null
}
$env:GOTMPDIR = $localTmp
Clear-Host

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [RADAR] RADIOGRAFIA INTEGRAL DE CODIGO - LIMPIO O ZURRADO?" -ForegroundColor Cyan
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

$goFiles = Get-ChildItem -Path . -Recurse -Filter "*.go" | Where-Object { $_.FullName -notmatch '\\vendor\\' }

foreach ($file in $goFiles) {
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

    # Declaraciones fuera de función (ej. 'if' sueltos)
    if ($content -match '(?m)^if\s+') {
        Report-Critical "Instruccion 'if' fuera de cuerpo de funcion en: $relPath"
    }
}

# ------------------------------------------------------------------------------
# 2. COLISIONES DE PAQUETES Y ARCHIVOS RESIDUALES
# ------------------------------------------------------------------------------
Write-Host "`n--- 2. ESTRUCTURA Y PAQUETES ---" -ForegroundColor Cyan

# Main en internal/
$internalMains = Get-ChildItem -Path ".\internal" -Recurse -Filter "*.go" | Where-Object { 
    (Get-Content $_.FullName -Raw) -match 'package main' 
}
if ($internalMains) {
    foreach ($item in $internalMains) {
        Report-Critical "Colision: 'package main' dentro de internal/: $($item.FullName.Replace($RepoRoot, '.'))"
    }
} else {
    Report-Ok "Estructura de paquetes en internal/ correcta."
}

# Duplicados en internal/models (AuditEvent redeclarado)
$modelFiles = Get-ChildItem -Path ".\internal\models" -Filter "*.go" -ErrorAction SilentlyContinue
$auditEventDeclarations = 0
foreach ($mf in $modelFiles) {
    if ((Get-Content $mf.FullName -Raw) -match 'type\s+AuditEvent\s+struct') {
        $auditEventDeclarations++
    }
}
if ($auditEventDeclarations -gt 1) {
    Report-Critical "Redeclaracion: 'AuditEvent' struct definido multiples veces en internal/models/"
} elseif ($auditEventDeclarations -eq 1) {
    Report-Ok "Definicion unica de AuditEvent en modelos."
}

# ------------------------------------------------------------------------------
# 3. SEGURIDAD Y CONTRATOS DE NEGOCIO
# ------------------------------------------------------------------------------
Write-Host "`n--- 3. SEGURIDAD Y REQUISITOS ---" -ForegroundColor Cyan

# Verificación de MaxBytesReader en handlers HTTP
$cmdMains = Get-ChildItem -Path ".\cmd" -Filter "main.go" -Recurse
foreach ($cm in $cmdMains) {
    $code = Get-Content $cm.FullName -Raw
    $rel = $cm.FullName.Replace($RepoRoot, ".")
    if ($code -notmatch 'http\.MaxBytesReader' -and $code -match 'r\.Body') {
        Report-Warn "Sin limite DoS (http.MaxBytesReader) en: $rel"
    }
}

# Verificación de Disclaimer en Reader
$readerMain = ".\cmd\reader\main.go"
if (Test-Path $readerMain) {
    $rCode = Get-Content $readerMain -Raw
    if ($rCode -notmatch 'MandatoryLegalDisclaimer') {
        Report-Critical "cmd/reader/main.go no incluye MandatoryLegalDisclaimer en su respuesta."
    } else {
        Report-Ok "Aviso legal obligatorio presente en rx-reader."
    }
}

# ------------------------------------------------------------------------------
# 4. PRUEBA DE FUEGO CON EL COMPILADOR DE GO
# ------------------------------------------------------------------------------
Write-Host "`n--- 4. PRUEBA DE FUEGO (COMPILADOR GO) ---" -ForegroundColor Cyan

Write-Host " Ejecutando 'go build ./...'..." -NoNewline
$buildOut = & go build ./... 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [FAIL]" -ForegroundColor Red
    Report-Critical "El proyecto NO COMPILA. Errores:`n$buildOut"
} else {
    Write-Host " [OK]" -ForegroundColor Green
    Report-Ok "go build ./... paso sin errores."
}

Write-Host " Ejecutando 'go test ./... -count=1'..." -NoNewline
$testOut = & go test ./... -count=1 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [FAIL]" -ForegroundColor Red
    Report-Critical "Las PRUEBAS FALLARON. Errores:`n$testOut"
} else {
    Write-Host " [OK]" -ForegroundColor Green
    Report-Ok "go test ./... paso sin errores."
}

Write-Host " Ejecutando 'go vet ./...'..." -NoNewline
$vetOut = & go vet ./... 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [FAIL]" -ForegroundColor Red
    Report-Critical "go vet encontro inconsistencias:`n$vetOut"
} else {
    Write-Host " [OK]" -ForegroundColor Green
    Report-Ok "go vet ./... paso sin observaciones."
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