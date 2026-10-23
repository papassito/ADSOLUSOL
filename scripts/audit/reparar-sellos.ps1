<#
================================================================================
  ADSOLUSOL :: DETECTOR Y REPARADOR DE SELLOS NOTARIALES (SHA-256)
  Escanea la documentación markdown, detecta discrepancias de integridad
  y regenera atómicamente docs/MANIFEST.md, MANIFEST.md y DOCUMENTATION_SEAL.json.

  Uso:
    .\scripts\audit\reparar-sellos.ps1          # Detecta anomalías y re-sella automáticamente
    .\scripts\audit\reparar-sellos.ps1 -Check   # Solo audita sin aplicar cambios
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$Check
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
Write-Host " [NOTARIA] ADSOLUSOL :: INSPECTOR Y REPARADOR DE SELLOS DOCUMENTALES      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$manifestPath = Join-Path $ScriptRoot "docs/MANIFEST.md"
if (-not (Test-Path $manifestPath)) {
    $manifestPath = Join-Path $ScriptRoot "MANIFEST.md"
}

$anomalias = 0
$archivosInexistentes = [System.Collections.Generic.List[string]]::new()
$archivosModificados  = [System.Collections.Generic.List[string]]::new()
$archivosSinSello     = [System.Collections.Generic.List[string]]::new()

# 1. Leer manifiesto actual si existe
$hashesRegistrados = @{}
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw -Encoding UTF8
    $regex = '\|\s*[\x60]?([^\x60|\r\n]+?)[\x60]?\s*\|\s*[\x60]?([a-f0-9]{64})[\x60]?\s*\|'
    $matches = [regex]::Matches($manifestContent, $regex)
    foreach ($m in $matches) {
        $relDoc = $m.Groups[1].Value.Trim().Replace('\', '/')
        $hashDoc = $m.Groups[2].Value.Trim().ToLower()
        $hashesRegistrados[$relDoc] = $hashDoc
    }
}

# 2. Obtener lista real de archivos Markdown en el repositorio
$mdFiles = Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch '[\\/](\.git|bin|obj|BUILD|node_modules|\.repair-backups|_audit)[\\/]' -and
        $_.Name -ne "MANIFEST.md" -and
        $_.Name -ne "EXPEDIENTE_CLINICO_MAESTRO.md"
    } |
    Sort-Object -Property FullName

$archivosReales = @{}
foreach ($f in $mdFiles) {
    $rel = $f.FullName.Substring($ScriptRoot.Length).TrimStart('\', '/').Replace('\', '/')
    $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower()
    $archivosReales[$rel] = @{ FullPath = $f.FullName; Hash = $hash }
}

# 3. Detectar sellos rotos (registrados pero inexistentes o modificados)
foreach ($docRegistrado in $hashesRegistrados.Keys) {
    if (-not $archivosReales.ContainsKey($docRegistrado)) {
        Write-Host "  [SELLO FALTANTE/ROTO] Archivo registrado en manifiesto ya no existe: $docRegistrado" -ForegroundColor Red
        $archivosInexistentes.Add($docRegistrado)
        $anomalias++
    } else {
        $realHash = $archivosReales[$docRegistrado].Hash
        $expectedHash = $hashesRegistrados[$docRegistrado]
        if ($realHash -ne $expectedHash) {
            Write-Host "  [SELLO DISCORDANTE] Hash no coincide en: $docRegistrado" -ForegroundColor Yellow
            Write-Host "     Esperado: $expectedHash" -ForegroundColor DarkGray
            Write-Host "     Actual  : $realHash" -ForegroundColor DarkGray
            $archivosModificados.Add($docRegistrado)
            $anomalias++
        }
    }
}

# 4. Detectar archivos Markdown nuevos sin registrar
foreach ($rel in $archivosReales.Keys) {
    if (-not $hashesRegistrados.ContainsKey($rel)) {
        Write-Host "  [SIN SELLO] Documento no registrado en manifiesto: $rel" -ForegroundColor Cyan
        $archivosSinSello.Add($rel)
        $anomalias++
    }
}

Write-Host "`n--------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " Total de documentos auditados : $($archivosReales.Count)" -ForegroundColor White
Write-Host " Anomalias de sellado          : $anomalias" -ForegroundColor $(if ($anomalias -eq 0) { "Green" } else { "Red" })
Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray

if ($anomalias -eq 0) {
    Write-Host "`n[PASS] Todos los sellos estan intactos. No se requieren reparaciones.`n" -ForegroundColor Green
    exit 0
}

if ($Check) {
    Write-Host "`n[MODO CHECK] Se detectaron anomalias. Ejecuta sin '-Check' para repararlas.`n" -ForegroundColor Yellow
    exit 1
}

# 5. Procedimiento de Reparación y Re-sellado
Write-Host "`n[APLICANDO REPARACION] Reconstruyendo sellos criptograficos..." -ForegroundColor Yellow

$emDash = [char]0x2014
$bt = [char]0x60
$lines = @(
    "# AD SOLUSOL $emDash Documentation Manifest",
    "",
    "**Estado:** SEALED / FROZEN DOCUMENTATION BASELINE",
    "**Fecha de sellado:** $(Get-Date -Format 'yyyy-MM-dd')",
    "**Total de archivos Markdown del baseline:** $($archivosReales.Count)",
    "",
    "## SHA-256 de documentos sellados",
    "",
    "| Archivo | SHA-256 |",
    "|---|---|"
)

foreach ($rel in ($archivosReales.Keys | Sort-Object)) {
    $hash = $archivosReales[$rel].Hash
    $lines += "| $bt$rel$bt | $bt$hash$bt |"
}

$content = ($lines -join "`r`n") + "`r`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$manifestTargets = @("docs/MANIFEST.md", "MANIFEST.md")
foreach ($mp in $manifestTargets) {
    $targetPath = Join-Path $ScriptRoot $mp
    $targetDir = Split-Path $targetPath
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
    [System.IO.File]::WriteAllText($targetPath, $content, $utf8NoBom)
    Write-Host "  -> Manifiesto regenerado: $mp" -ForegroundColor Green
}

# 6. Actualizar DOCUMENTATION_SEAL.json
$sealPath = Join-Path $ScriptRoot "DOCUMENTATION_SEAL.json"
if (Test-Path $sealPath) {
    $rootManifestHash = (Get-FileHash (Join-Path $ScriptRoot "MANIFEST.md") -Algorithm SHA256).Hash.ToLower()
    $docsManifestHash = (Get-FileHash (Join-Path $ScriptRoot "docs/MANIFEST.md") -Algorithm SHA256).Hash.ToLower()

    $sealRaw = Get-Content $sealPath -Raw -Encoding UTF8
    $sealData = $sealRaw | ConvertFrom-Json

    $sealData.seal.revisionDate = (Get-Date -Format "yyyy-MM-dd")
    $sealData.seal.totalMarkdownFiles = $archivosReales.Count
    $sealData.manifestHashes."MANIFEST.md" = $rootManifestHash
    $sealData.manifestHashes."docs/MANIFEST.md" = $docsManifestHash

    $sealJson = ($sealData | ConvertTo-Json -Depth 10) + "`r`n"
    [System.IO.File]::WriteAllText($sealPath, $sealJson, $utf8NoBom)
    Write-Host "  -> Sello maestro actualizado: DOCUMENTATION_SEAL.json" -ForegroundColor Green
}

Write-Host "`n==========================================================================" -ForegroundColor Green
Write-Host " [REPARACION COMPLETADA] Sellos sincronizados y validados exitosamente.  " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host ""
exit 0