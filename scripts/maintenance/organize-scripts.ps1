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
    "audit-live.ps1"            = "audit"
    "audit-tree.ps1"            = "audit"
    "radiografia_codigo.ps1"    = "audit"
    "Verificar-Errores.ps1"     = "audit"

    # Build & Release
    "BUILD-ADSOLUSOL.ps1"       = "build"
    "release.ps1"               = "build"

    # Maintenance & Tooling
    "generate_docs.ps1"         = "maintenance"
    "Show-ProjectTree.ps1"      = "maintenance"
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
Write-Host "--- ELIMINANDO SCRIPTS OBSOLETOS E INSERVIBLES ---" -ForegroundColor Yellow
$obsoleteScripts = @(
    "clean-encodings.ps1",
    "cleanup-project.ps1",
    "fix-structure-and-scripts.ps1",
    "reparar-adsolusol.ps1",
    "REPARAR-FINAL.ps1",
    "seal_adsolusol_release.ps1",
    "chismoso.ps1",
    "audit-live.ps1",
    "radiografia_codigo.ps1",
    "Verificar-Errores.ps1",
    "CALIFICADOR_MODULOS.ps1",
    "Calificar-Proyecto.ps1",
    "Show-ProjectTree.ps1",
    "release.ps1",
    "Calificar-Proyecto.ps1",
    "push.ps1",
    "Start-Dev.ps1",
    "stress_test.ps1",
    "sync-main.ps1",
    "update_github.ps1",
    "autopsia_integridad.cmd",
    "scripts\chismoso.ps1",
    "scripts\audit_chismoso.ps1",
    "scripts\audit_ultra-mitotero.ps1",
    "scripts\check_structure.ps1",
    "scripts\radiografia_codigo.ps1",
    "Health-Check.ps1",
    "Run-Master-Audit.ps1",
    "update_manifest.ps1"
)

foreach ($obs in $obsoleteScripts) {
    $path = Join-Path $Root $obs
    if (Test-Path $path) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
        Write-Host "[ELIMINADO] Script obsoleto/duplicado: $obs" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "--- ELIMINANDO DOCUMENTOS ESPEJO EN DOCS/ ---" -ForegroundColor Yellow
$mirrorDocs = @(
    "docs\ADSOLUSOL.md",
    "docs\AI-AD.md",
    "docs\AI.md",
    "docs\CAMPAIGN.md",
    "docs\COMPONENTS.md",
    "docs\CONTRACTS.md",
    "docs\INTEGRITY.md",
    "docs\MAP.md",
    "docs\MARKETING-API.md",
    "docs\MARKETING-BRAIN.md",
    "docs\MARKETING.md",
    "docs\MOTOR.md",
    "docs\ONION.md",
    "docs\ORCHESTA.md",
    "docs\SEO.md",
    "docs\SITEMAP.md",
    "docs\VALIDATE.md"
)
foreach ($doc in $mirrorDocs) {
    $p = Join-Path $Root $doc
    if (Test-Path $p) {
        Remove-Item $p -Force -ErrorAction SilentlyContinue
        Write-Host "[ELIMINADO] Documento espejo: $doc" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Organization complete." -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan