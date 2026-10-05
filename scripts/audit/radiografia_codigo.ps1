<#[
  ADSOLUSOL :: RADIOGRAFIA FORENSE DE CODIGO
  Solo lectura por defecto. Use -Fix para reparar FFFD y mojibake detectado.
]#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [string]$Path = '',
    [switch]$Fix
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$base = (Resolve-Path $Root).Path
while ($base -and -not (Test-Path (Join-Path $base 'ADSOLUSOL.sln'))) {
    $parent = Split-Path $base -Parent
    if ($parent -eq $base) { break }
    $base = $parent
}
$utf8 = New-Object Text.UTF8Encoding($false)
$targets = @()
if ($Path) {
    $resolvedTarget = Resolve-Path (Join-Path $base $Path) -ErrorAction SilentlyContinue
    if ($resolvedTarget) { $targets = @((Get-Item $resolvedTarget.Path)) }
} else {
    $targets = @(Get-ChildItem $base -Recurse -File -Include *.cs,*.razor,*.md,*.json,*.ps1,*.ts,*.tsx,*.html -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\(\.git|bin|obj|node_modules|dist|BUILD)\\' })
}
$corrupt = 0; $findings = 0; $processed = 0
Write-Host '===========================================================================' -ForegroundColor Cyan
Write-Host ' RADIOGRAFIA FORENSE DE CODIGO' -ForegroundColor Cyan
Write-Host "Directorio Base: $base`n" -ForegroundColor DarkGray
foreach ($file in $targets) {
    if (-not $file) { continue }
    $processed++
    $raw = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $hasReplacement = $raw.Contains([char]0xFFFD)
    $hasMojibake = $raw -match '(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})'
    if (-not ($hasReplacement -or $hasMojibake)) { continue }
    $corrupt++
    Write-Host "[ANOMALIA] $($file.FullName)" -ForegroundColor Yellow
    $lines = [IO.File]::ReadAllLines($file.FullName, [Text.Encoding]::UTF8)
    for ($n = 0; $n -lt $lines.Length; $n++) {
        if ($lines[$n].Contains([char]0xFFFD) -or $lines[$n] -match '(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})') {
            $findings++
            Write-Host "  Linea $($n + 1): $($lines[$n].Trim())" -ForegroundColor Gray
        }
    }
    if ($Fix) {
        $clean = $raw.Replace([string][char]0xFFFD, '')
        if ($clean -match '(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})') {
            try {
                $clean = [Text.Encoding]::UTF8.GetString([Text.Encoding]::GetEncoding(1252).GetBytes($clean))
            } catch {}
        }
        [IO.File]::WriteAllText($file.FullName, $clean, $utf8)
        Write-Host '  Reparado con -Fix.' -ForegroundColor Green
    }
}
Write-Host "`nArchivos procesados : $processed" -ForegroundColor DarkGray
Write-Host "Archivos anomalos   : $corrupt" -ForegroundColor Yellow
Write-Host "Hallazgos           : $findings" -ForegroundColor Yellow
if ($corrupt -eq 0) { Write-Host 'RADIOGRAFIA LIMPIA.' -ForegroundColor Green }
elseif (-not $Fix) { Write-Host 'Use -Fix para reparar los archivos detectados.' -ForegroundColor Yellow }
exit 0
