# =============================================================================
# ADSOLUSOL — AUDITORÍA MILIMÉTRICA ULTRA CHISMOSA v4.5.2 (DOTNET 8)
# =============================================================================

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$RunBuild = $true
)

$ErrorActionPreference = "Continue"
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }

# Detección y localización de dotnet.exe
$dotnetExe = "C:\Users\Radio 2027\Documents\Codex\tools\dotnet\dotnet.exe"
if (-not (Test-Path $dotnetExe)) {
    $dotnetExe = Get-Command "dotnet" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $dotnetExe) {
        if (Test-Path "C:\Program Files\dotnet\dotnet.exe") {
            $dotnetExe = "C:\Program Files\dotnet\dotnet.exe"
        } elseif (Test-Path "C:\Program Files (x86)\dotnet\dotnet.exe") {
            $dotnetExe = "C:\Program Files (x86)\dotnet\dotnet.exe"
        }
    }
}

$StartedAt = Get-Date
$AuditDir = Join-Path $Root "_audit"
$JsonReport = Join-Path $AuditDir "audit_report.json"

$Stats = [ordered]@{ Critical = 0; High = 0; Medium = 0; Low = 0; Info = 0 }
$Findings = [System.Collections.Generic.List[psobject]]::new()

function Write-Section([string]$title) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host $title.ToUpper() -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor DarkGray
}

function Add-Finding([string]$Severity, [string]$Code, [string]$Category, [string]$Message, [string]$File = "") {
    switch ($Severity.ToUpper()) {
        "CRITICAL" { $Stats.Critical++; $color = "Red" }
        "HIGH"     { $Stats.High++;     $color = "DarkRed" }
        "MEDIUM"   { $Stats.Medium++;   $color = "Yellow" }
        "LOW"      { $Stats.Low++;      $color = "Gray" }
        default    { $Stats.Info++;     $color = "DarkGray" }
    }

    $f = [pscustomobject]@{
        Severity = $Severity.ToUpper()
        Code     = $Code
        Category = $Category
        Message  = $Message
        File     = $File
    }
    $Findings.Add($f)
    $loc = if ($File) { " [$File]" } else { "" }
    Write-Host ("[{0}] [{1}] {2}{3}" -f $f.Severity, $f.Code, $f.Message, $loc) -ForegroundColor $color
}

Write-Section 'FASE 0 — ALCANCE ADSOLUSOL NET 8'
Write-Host "Raiz del Proyecto: $Root" -ForegroundColor Yellow

$slnPath = Join-Path $Root "ADSOLUSOL.sln"
if (Test-Path -LiteralPath $slnPath) {
    Add-Finding -Severity "INFO" -Code "ADS-SLN-OK" -Category "SCOPE" -Message "ADSOLUSOL.sln localizado." -File "ADSOLUSOL.sln"
} else {
    Add-Finding -Severity "CRITICAL" -Code "ADS-SLN-MISSING" -Category "SCOPE" -Message "ADSOLUSOL.sln no encontrado."
}

# 1. Validar sintaxis JSON
Write-Section 'FASE 1 — SINTAXIS JSON EN CONFIGURACIONES'
$jsonFiles = Get-ChildItem -Path $Root -Recurse -Filter "*.json" | Where-Object { $_.FullName -notmatch '\\(bin|obj|_audit)\\' }
foreach ($j in $jsonFiles) {
    $rel = $j.FullName.Replace($Root, "").TrimStart("\", "/")
    try {
        $content = Get-Content -LiteralPath $j.FullName -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            Add-Finding -Severity "CRITICAL" -Code "ADS-JSON-EMPTY" -Category "CONFIG" -Message "Archivo JSON vacio (0 bytes)." -File $rel
        } else {
            $null = ConvertFrom-Json $content -ErrorAction Stop
            Add-Finding -Severity "INFO" -Code "ADS-JSON-OK" -Category "CONFIG" -Message "Sintaxis JSON valida." -File $rel
        }
    } catch {
        Add-Finding -Severity "CRITICAL" -Code "ADS-JSON-BAD" -Category "CONFIG" -Message ("Error de sintaxis JSON: {0}" -f $_.Exception.Message) -File $rel
    }
}

# 2. Compilación Real de .NET
Write-Section 'FASE 2 — PRUEBA DE COMPILACION REAL DOTNET BUILD'
if ($RunBuild -and (Test-Path -LiteralPath $slnPath)) {
    if (-not $dotnetExe) {
        Add-Finding -Severity "CRITICAL" -Code "ADS-BUILD-NODOTNET" -Category "BUILD" -Message "No se encontro dotnet.exe en el sistema."
    } else {
        Write-Host ">>> Ejecutando build con: $dotnetExe" -ForegroundColor Yellow
        $buildOut = & $dotnetExe build $slnPath --nologo 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-Finding -Severity "INFO" -Code "ADS-BUILD-PASS" -Category "BUILD" -Message "BUILD PASS: Compilacion exitosa (0 Errores)."
        } else {
            Add-Finding -Severity "CRITICAL" -Code "ADS-BUILD-FAIL" -Category "BUILD" -Message "BUILD FAILURE: La solucion arrojo errores al compilar."
        }
    }
}

# 3. Resumen y Sello
Write-Section 'RESUMEN DE AUDITORIA'
$Gate = if ($Stats.Critical -gt 0) { "FAIL" } elseif ($Stats.High -gt 0) { "REVIEW" } else { "PASS" }

New-Item -ItemType Directory -Path $AuditDir -Force | Out-Null
$report = [ordered]@{
    Product  = "ADSOLUSOL"
    Root     = $Root
    Gate     = $Gate
    Stats    = $Stats
    Findings = $Findings
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $JsonReport -Encoding UTF8

Write-Host ""
Write-Host ("GATE RESULT : {0}" -f $Gate) -ForegroundColor $(if($Gate -eq "FAIL"){"Red"}else{"Green"})
Write-Host ("CRITICAL    : {0}" -f $Stats.Critical)
Write-Host ("INFO        : {0}" -f $Stats.Info)
Write-Host ""
Write-Host "Reporte JSON generado en: $JsonReport" -ForegroundColor Cyan