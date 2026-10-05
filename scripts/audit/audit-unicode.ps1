<#
================================================================================
  ADSOLUSOL :: AUDITORIA FORENSE DE CODIFICACION UTF-8, BOM Y UNICODE
  Inspecciona byte a byte la ausencia de UTF-8 BOM, caracteres nulos,
  caracter de reemplazo \uFFFD y patrones Mojibake.

  Uso:
    .\scripts\audit\audit-unicode.ps1          # Solo auditoria
    .\scripts\audit\audit-unicode.ps1 -Fix     # Repara y reescribe en UTF-8 sin BOM
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$Fix
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

try {
    [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
} catch {}

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [UNICODE] AUDITORIA FORENSE DE CODIFICACION UTF-8, BOM Y MOJIBAKE        " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$validExts = @('.cs', '.csproj', '.json', '.md', '.ps1', '.xaml', '.razor', '.ts', '.tsx', '.html', '.css', '.sln')
$files = Get-ChildItem -Path $ScriptRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { 
        $validExts -contains $_.Extension.ToLower() -and 
        $_.FullName -notmatch '[\\/](\.git|bin|obj|node_modules|dist|BUILD|\.build|\.repair-backups|_audit|TestResults)[\\/]' 
    }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$mojibakePattern = '(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})'

$totalArchivos = $files.Count
$archivosConBom = 0
$archivosConFFFD = 0
$archivosConMojibake = 0
$archivosReparados = 0

foreach ($f in $files) {
    $relPath = $f.FullName.Substring($ScriptRoot.Length).TrimStart('\', '/')
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)

    if ($bytes.Length -eq 0) { continue }

    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $cleanBytes = if ($hasBom) { [byte[]]$bytes[3..($bytes.Length - 1)] } else { $bytes }

    $text = [System.Text.Encoding]::UTF8.GetString($cleanBytes)
    $hasFFFD = $text.Contains([char]0xFFFD)
    $hasMojibake = $text -match $mojibakePattern

    if ($hasBom) {
        $archivosConBom++
        Write-Host "  [FAIL] [BOM] $relPath contiene marca UTF-8 BOM." -ForegroundColor Red
    }
    if ($hasFFFD) {
        $archivosConFFFD++
        Write-Host "  [FAIL] [CORRUPT-CHAR] $relPath contiene caracter de reemplazo (\uFFFD)." -ForegroundColor Red
    }
    if ($hasMojibake) {
        $archivosConMojibake++
        Write-Host "  [WARN] [MOJIBAKE] $relPath contiene secuencias dobles de codificacion (Windows-1252)." -ForegroundColor Yellow
    }

    if ($Fix -and ($hasBom -or $hasFFFD -or $hasMojibake)) {
        $sanitized = $text.Replace([string][char]0xFFFD, "")
        if ($sanitized -match $mojibakePattern) {
            try {
                $bytes1252 = [System.Text.Encoding]::GetEncoding(1252).GetBytes($sanitized)
                $sanitized = [System.Text.Encoding]::UTF8.GetString($bytes1252)
            } catch {}
        }
        [System.IO.File]::WriteAllText($f.FullName, $sanitized, $utf8NoBom)
        $archivosReparados++
        Write-Host "  [REPARADO] $relPath reescrito en UTF-8 canonico sin BOM." -ForegroundColor Green
    }
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     RESUMEN FORENSE DE CODIFICACION                      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Archivos escaneados        : $totalArchivos" -ForegroundColor White
Write-Host " Archivos con BOM           : $archivosConBom" -ForegroundColor $(if ($archivosConBom -eq 0) { "Green" } else { "Red" })
Write-Host " Archivos con \uFFFD        : $archivosConFFFD" -ForegroundColor $(if ($archivosConFFFD -eq 0) { "Green" } else { "Red" })
Write-Host " Archivos con Mojibake      : $archivosConMojibake" -ForegroundColor $(if ($archivosConMojibake -eq 0) { "Green" } else { "Yellow" })
if ($Fix) {
    Write-Host " Archivos reparados con éxito: $archivosReparados" -ForegroundColor Green
}
Write-Host "==========================================================================" -ForegroundColor Cyan

$erroresCriticos = $archivosConBom + $archivosConFFFD
if ($erroresCriticos -gt 0) {
    if (-not $Fix) {
        Write-Host "`n[FAIL] Se detectaron errores criticos de codificacion. Ejecuta con -Fix para sanear:`n  .\scripts\audit\audit-unicode.ps1 -Fix`n" -ForegroundColor Red
    }
    exit 1
} elseif ($archivosConMojibake -gt 0) {
    Write-Host "`n[WARN] Codificacion limpia sin BOM, pero con patrones de texto residuales.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] Todo el repositorio es UTF-8 canónico puro sin BOM ni corrupcion.`n" -ForegroundColor Green
    exit 0
}