<#
================================================================================
  ADSOLUSOL :: AUDITORIA FORENSE DE MOJIBAKE Y CORRUPCION UTF-8
  Detecta secuencias de doble codificacion (Windows-1252 interpretado como UTF-8)
  y caracteres de reemplazo (\uFFFD).

  Uso:
    .\scripts\audit\audit-mojibake.ps1
    .\scripts\audit\audit-mojibake.ps1 -Fix
    .\scripts\audit\audit-mojibake.ps1 -Path "docs/EXPEDIENTE_CLINICO_MAESTRO.md"
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [string]$Path = "",
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
Write-Host " ðŸ” ADSOLUSOL :: AUDITORIA FORENSE DE MOJIBAKE                            " -ForegroundColor Cyan
Write-Host " [MOJIBAKE] ADSOLUSOL :: AUDITORIA FORENSE DE MOJIBAKE                   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

if (-not [string]::IsNullOrWhiteSpace($Path)) {
    $targetPath = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $ScriptRoot $Path }
    $ArchivosObjetivo = @(Get-Item $targetPath -ErrorAction SilentlyContinue)
} else {
    $Extensiones = @("*.cs", "*.razor", "*.md", "*.json", "*.ps1", "*.ts", "*.tsx", "*.html")
    $ArchivosObjetivo = Get-ChildItem -Path $ScriptRoot -Recurse -Include $Extensiones -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](\.git|bin|obj|node_modules|dist|BUILD)[\\/]' }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$totalArchivos = 0
$archivosConMojibake = 0
$totalIncidencias = 0

$mojibakeRegex = '(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})'

foreach ($file in $ArchivosObjetivo) {
    $totalArchivos++
    $rel = $file.FullName.Substring($ScriptRoot.Length).TrimStart('\', '/')
    $rawText = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

    $hasMojibake = $rawText -match $mojibakeRegex
    $hasReplacement = $rawText.Contains([char]0xFFFD)

    if (-not $hasMojibake -and -not $hasReplacement) {
        continue
    }

    $archivosConMojibake++
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "[HALLAZGO] $rel" -ForegroundColor Red

    $lines = [System.IO.File]::ReadAllLines($file.FullName, [System.Text.Encoding]::UTF8)
    for ($lineIdx = 0; $lineIdx -lt $lines.Length; $lineIdx++) {
        $lineNum = $lineIdx + 1
        $lineContent = $lines[$lineIdx]

        if ($lineContent.Contains([char]0xFFFD)) {
            $totalIncidencias++
            $col = $lineContent.IndexOf([char]0xFFFD) + 1
            Write-Host "  -> [Linea $lineNum, Col $col] Caracter corrupto \uFFFD" -ForegroundColor Red
            Write-Host "     Texto: $($lineContent.Trim())" -ForegroundColor DarkGray
        }

        if ($lineContent -match $mojibakeRegex) {
            $totalIncidencias++
            $col = $lineContent.IndexOf($Matches[1]) + 1
            Write-Host "  -> [Linea $lineNum, Col $col] Secuencia Mojibake: '$($Matches[1])'" -ForegroundColor Yellow
            Write-Host "     Texto: $($lineContent.Trim())" -ForegroundColor DarkGray
        }
    }

    if ($Fix) {
        $cleaned = $rawText.Replace([string][char]0xFFFD, "")
        if ($cleaned -match $mojibakeRegex) {
            try {
                $bytesBroken = [System.Text.Encoding]::GetEncoding(1252).GetBytes($cleaned)
                $cleaned = [System.Text.Encoding]::UTF8.GetString($bytesBroken)
            } catch {}
        }
        [System.IO.File]::WriteAllText($file.FullName, $cleaned, $utf8NoBom)
        Write-Host "  [SANEADO] Archivo reescrito en UTF-8 canonico sin BOM." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "                     RESUMEN DE AUDITORIA MOJIBAKE                        " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$colorArchivos = if ($archivosConMojibake -eq 0) { "Green" } else { "Red" }
$colorPatrones = if ($totalIncidencias -eq 0) { "Green" } else { "Yellow" }

Write-Host " Total archivos escaneados  : $totalArchivos" -ForegroundColor White
Write-Host " Archivos con anomalias     : $archivosConMojibake" -ForegroundColor $colorArchivos
Write-Host " Total de patrones corruptos: $totalIncidencias" -ForegroundColor $colorPatrones
Write-Host "==========================================================================" -ForegroundColor Cyan

Write-Host ""
if ($archivosConMojibake -eq 0) {
    Write-Host "[PASS] Cero secuencias Mojibake detectadas. Todos los archivos son UTF-8 puro." -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    if (-not $Fix) {
        Write-Host "[ADVERTENCIA] Se detectaron anomalias. Ejecuta con '-Fix' para autoreparar:" -ForegroundColor Yellow
        Write-Host "  .\scripts\audit\audit-mojibake.ps1 -Fix" -ForegroundColor Yellow
    } else {
        Write-Host "[REPARACION] Los archivos afectados fueron procesados." -ForegroundColor Green
    }
    Write-Host ""
    exit 1
}