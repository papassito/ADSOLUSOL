<#
================================================================================
  ADSOLUSOL - SCRIPT & TOOLING ORGANIZER
  Mueve los scripts de la raíz a una estructura de carpetas organizada
  y elimina artefactos innecesarios.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Get-Location).Path
}

$ScriptsDir = Join-Path $Root "scripts"
New-Item -ItemType Directory -Path $ScriptsDir -ErrorAction SilentlyContinue | Out-Null

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL - SCRIPT & TOOLING ORGANIZER" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Organizing scripts into: $ScriptsDir" -ForegroundColor Yellow
Write-Host ""

$scriptMap = @{
    # Audit & Quality
    "auditar_todo.ps1"          = "audit"
    "autopsia_integridad.ps1"   = "audit"
    "junta_medica.ps1"          = "audit"
    "radiologico_forense.ps1"   = "audit"
    "smoke-test.ps1"            = "audit"

    # Build & Release
    "BUILD-ADSOLUSOL.ps1"       = "build"
    "release.ps1"               = "build"

    # Maintenance & Tooling
    "generate_docs.ps1"         = "maintenance"
}

$rootScripts = Get-ChildItem -Path $Root -Filter "*.ps1" -File | Where-Object { $_.Name -ne "organize-scripts.ps1" }

foreach ($script in $rootScripts) {
    if ($scriptMap.ContainsKey($script.Name)) {
        $subfolder = $scriptMap[$script.Name]
        $targetDir = Join-Path $ScriptsDir $subfolder
        $targetPath = Join-Path $targetDir $script.Name

        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
            Write-Host "[+] Created directory: scripts\$subfolder" -ForegroundColor DarkCyan
        }

        Move-Item -Path $script.FullName -Destination $targetPath -Force
        Write-Host "[MOVED] $($script.Name) -> scripts\$subfolder\" -ForegroundColor Green
    } else {
        Write-Host "[SKIPPED] Uncategorized script: $($script.Name)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "--- EMPTY SCRIPT CLEANUP ---" -ForegroundColor Yellow
$emptyScripts = @("Health-Check.ps1", "Run-Master-Audit.ps1", "update_manifest.ps1")

foreach ($es in $emptyScripts) {
    $path = Join-Path $Root $es
    if (Test-Path $path) {
        $fileInfo = Get-Item $path
        if ($fileInfo.Length -eq 0) {
            Remove-Item $path -Force -ErrorAction SilentlyContinue
            Write-Host "[DELETED] Removed 0-byte script: $es" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Organization complete." -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan