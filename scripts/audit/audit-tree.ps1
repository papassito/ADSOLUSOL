<#
================================================================================
  ADSOLUSOL :: AUDITORIA FORENSE DEL ARBOL ESTRUCTURAL (TREE AUDIT)
  Fiscaliza la higiene de la raiz, la segregacion de capas Onion,
  la sanidad de docs/STRUCTURE.md y la ausencia de ramas rotas o duplicados.

  Uso:
    .\scripts\audit\audit-tree.ps1
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

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [TREE] ADSOLUSOL :: AUDITORIA FORENSE DEL ARBOL Y TOPOLOGIA             " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$fallasTree = 0
$advertenciasTree = 0

function Report-TreeFail([string]$Check, [string]$Mensaje) {
    Write-Host "  [FAIL] [$Check] $Mensaje" -ForegroundColor Red
    $script:fallasTree++
}

function Report-TreeWarn([string]$Check, [string]$Mensaje) {
    Write-Host "  [WARN] [$Check] $Mensaje" -ForegroundColor Yellow
    $script:advertenciasTree++
}

function Report-TreePass([string]$Check, [string]$Mensaje) {
    Write-Host "  [PASS] [$Check] $Mensaje" -ForegroundColor Green
}

# 1. Higiene de Raíz (.csproj y archivos residuales)
Write-Host "[1/5] Auditando higiene de la raiz del repositorio..." -ForegroundColor Yellow
$strayCsproj = Get-ChildItem -Path $ScriptRoot -Filter "*.csproj" -File -ErrorAction SilentlyContinue
if ($strayCsproj.Count -gt 0) {
    foreach ($p in $strayCsproj) {
        Report-TreeFail "ROOT-CLEAN" "Proyecto .csproj huerfano en la raiz: $($p.Name)"
    }
} else {
    Report-TreePass "ROOT-CLEAN" "Cero proyectos .csproj huerfanos en la raiz."
}

$parasiteFolders = @("ADSOLUSOL", "adsolusol2027", "ADSOLUSOL2027", "Backup", "BackUP", ".tmp_build", "TestResults", "Restaurar INTERFAZ")
foreach ($folder in $parasiteFolders) {
    if (Test-Path (Join-Path $ScriptRoot $folder)) {
        Report-TreeFail "ROOT-POLLUTION" "Carpeta no autorizada o parasita detectada en la raiz: $folder/"
    }
}

# 2. Topología Canónica Onion (src/ y tests/)
Write-Host "`n[2/5] Verificando presencia de capas arquitectonicas obligatorias..." -ForegroundColor Yellow
$requiredLayers = @(
    "src/ADSOLUSOL.Domain/ADSOLUSOL.Domain.csproj",
    "src/ADSOLUSOL.Application/ADSOLUSOL.Application.csproj",
    "src/ADSOLUSOL.Infrastructure/ADSOLUSOL.Infrastructure.csproj",
    "src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj",
    "src/ADSOLUSOL.Presentation.Desktop/ADSOLUSOL.Presentation.Desktop.csproj",
    "tests/ADSOLUSOL.RegressionTests/ADSOLUSOL.RegressionTests.csproj",
    "tests/ADSOLUSOL.ArchitectureTests/ADSOLUSOL.ArchitectureTests.csproj"
)

foreach ($layer in $requiredLayers) {
    if (Test-Path (Join-Path $ScriptRoot $layer)) {
        Report-TreePass "TOPOLOGY-ONION" "Capa confirmada: $layer"
    } else {
        Report-TreeFail "TOPOLOGY-ONION" "Capa arquitectonica faltante: $layer"
    }
}

# 3. Consistencia y Glifos de docs/STRUCTURE.md
Write-Host "`n[3/5] Fiscalizando sanidad y glifos en docs/STRUCTURE.md..." -ForegroundColor Yellow
$structureDoc = Join-Path $ScriptRoot "docs/STRUCTURE.md"
if (Test-Path $structureDoc) {
    $lines = [System.IO.File]::ReadAllLines($structureDoc, [System.Text.Encoding]::UTF8)
    $brokenGlyphs = 0

    for ($i = 0; $i -lt ($lines.Length - 1); $i++) {
        $curr = $lines[$i]
        $next = $lines[$i + 1]

        # Deteccion de rama cerrada prematuramente (cierre terminal seguido de hermano en el mismo nivel)
        if ($curr -match '^(?<indent>.*)\u2514\u2500\u2500\s+(?!.*\.(?:csproj|json|cs|md|ts|tsx)$)' -and $next -match ("^" + [regex]::Escape($Matches['indent']) + "\u251C\u2500\u2500")) {
            Report-TreeWarn "STRUCTURE-GLYPH" "Rama rota en linea $($i + 1): cierre terminal seguido de nodo hermano."
            $brokenGlyphs++
        }
    }

    if ($brokenGlyphs -eq 0) {
        Report-TreePass "STRUCTURE-GLYPH" "Glifos del arbol estructural balanceados correctamente."
    }
} else {
    Report-TreeFail "STRUCTURE-FILE" "Archivo de documentacion docs/STRUCTURE.md ausente."
}

# 4. Detección de Archivos Espejo / Duplicados en docs/
Write-Host "`n[4/5] Auditando duplicidad y espejo documental en docs/..." -ForegroundColor Yellow
$rootDocs = Get-ChildItem -Path (Join-Path $ScriptRoot "docs") -Filter "*.md" -File -ErrorAction SilentlyContinue
$mirrorDuplicates = 0

foreach ($doc in $rootDocs) {
    $subMatches = Get-ChildItem -Path (Join-Path $ScriptRoot "docs") -Recurse -Filter $doc.Name -File -ErrorAction SilentlyContinue |
        Where-Object { $_.DirectoryName -ne $doc.DirectoryName }

    if ($subMatches.Count -gt 0) {
        $paths = ($subMatches | ForEach-Object { $_.FullName.Substring($ScriptRoot.Length).TrimStart('\', '/') }) -join ", "
        Report-TreeWarn "DOC-MIRROR" "Documento duplicado en raiz de docs/ y en subcarpeta(s): $($doc.Name) -> [$paths]"
        $mirrorDuplicates++
    }
}
if ($mirrorDuplicates -eq 0) {
    Report-TreePass "DOC-MIRROR" "Cero duplicaciones espejo en docs/."
}

# 5. Sanidad de Scripts
Write-Host "`n[5/5] Verificando organizacion de scripts en scripts/..." -ForegroundColor Yellow
$allowedRootScripts = @("push.ps1")
$scriptsInRoot = Get-ChildItem -Path $ScriptRoot -Filter "*.ps1" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin $allowedRootScripts }

if ($scriptsInRoot.Count -gt 0) {
    foreach ($s in $scriptsInRoot) {
        Report-TreeWarn "SCRIPT-LOCATION" "Script .ps1 ubicado en la raiz: $($s.Name) (debe residir en scripts/)."
    }
} else {
    Report-TreePass "SCRIPT-LOCATION" "Scripts debidamente categorizados en scripts/."
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN DEL ARBOL ESTRUCTURAL                       " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Criticas : $fallasTree" -ForegroundColor $(if ($fallasTree -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias          : $advertenciasTree" -ForegroundColor $(if ($advertenciasTree -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($fallasTree -gt 0) {
    Write-Host ""
    Write-Host "[FAIL] Se detectaron anomalias estructurales en el arbol del repositorio." -ForegroundColor Red
    Write-Host ""
    exit 1
} else {
    Write-Host ""
    Write-Host "[PASS] La estructura del repositorio es solida, canonica y uniforme." -ForegroundColor Green
    Write-Host ""
    exit 0
}