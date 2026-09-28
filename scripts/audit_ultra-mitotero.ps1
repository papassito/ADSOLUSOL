<#
 - NOT_DETECTED != DOES_NOT_EXIST
 - STRING_FOUND != IMPLEMENTED
 - IMPORT_FOUND != FUNCTIONAL_USAGE
 - FORMAT_FAIL != SYNTAX_ERROR
 - DOCUMENT_FOUND != AUTHORITATIVE
 - DECLARED != EXECUTED
#>

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Get-Command Show-Info -ErrorAction SilentlyContinue)) {
    function Show-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
}
if (-not (Get-Command Show-Fail -ErrorAction SilentlyContinue)) {
    function Show-Fail($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red }
}
if (-not (Get-Command Add-Pass -ErrorAction SilentlyContinue)) {
    function Add-Pass($msg) { Write-Host "[PASS] $msg" -ForegroundColor Green }
}
if (-not (Get-Command Add-Finding -ErrorAction SilentlyContinue)) {
    function Add-Finding {
        param($Code, $Category, $Description, $Severity, $EvidenceScope, $Evidence)
        Write-Host "[$Severity] [$Code] $Description ($($EvidenceScope): $Evidence)" -ForegroundColor $(if ($Severity -eq "CRITICAL") { "Red" } else { "Yellow" })
    }
}
if (-not $RepoRoot) {
    $RepoRoot = if ($PSScriptRoot) { Split-Path -Path $PSScriptRoot -Parent } else { (Get-Location).Path }
}


Write-Host ""
Show-Info "[FASE 1C] Inspeccionando polucion estructural (huerfanos, basura)..."

# 0. Verificar carpetas parásitas o anidadas de otros proyectos
$ghostDirs = @("ADSOLUSOL")
foreach ($gDir in $ghostDirs) {
    if (Test-Path (Join-Path $RepoRoot $gDir)) {
        Add-Finding -Code "ADS-GHOST-DIR" -Category "POLLUTION_NESTED_ROOT" -Description "Directorio parasito '$gDir/' detectado en la raiz." -Severity "CRITICAL" -EvidenceScope "root" -Evidence $gDir
        Show-Fail "[POLUCION] Carpeta anidada no autorizada: $gDir/"
    } else {
        Add-Pass "[LIMPIEZA] Sin rastro de carpeta parasita '$gDir/'."
    }
}

# 1. Archivos desktop.ini
$desktopIniFiles = @(Get-ChildItem -Path $RepoRoot -Filter "desktop.ini" -Recurse -Force -ErrorAction SilentlyContinue)
if ($desktopIniFiles.Count -gt 0) {
    foreach ($ini in $desktopIniFiles) {
        $rel = $ini.FullName.Replace($RepoRoot, ".")
        Add-Finding -Code "ADS-JUNK-DESKTOPINI" -Category "JUNK_FILE" -Description "Archivo de sistema desktop.ini detectado." -Severity "LOW" -EvidenceScope "file" -Evidence $rel
        Show-Fail "[POLUCION] desktop.ini detectado en: $rel"
    }
} else {
    Add-Pass "[LIMPIEZA] Cero archivos desktop.ini en el repositorio."
}

# 2. Detección de archivos duplicados (.cs, .json, .ts)
$scannableFiles = @(Get-ChildItem -LiteralPath $RepoRoot -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { 
        $_.FullName -notmatch '[\\/](\.git|bin|obj|BUILD|\.build|\.repair-backups|node_modules|dist|coverage|\.pids)[\\/]' -and
        $_.Length -gt 0 -and
        $_.Extension -in @('.cs', '.ts', '.tsx', '.json')
    })

$duplicateSets = @($scannableFiles | Get-FileHash -Algorithm SHA256 | Group-Object Hash | Where-Object { $_.Count -gt 1 })
if ($duplicateSets.Count -gt 0) {
    foreach ($set in $duplicateSets) {
        $fileList = ($set.Group.FullName | ForEach-Object { $_.Replace($RepoRoot, ".") }) -join "; "
        Add-Finding -Code "ADS-DUP-FILE" -Category "DUPLICATE_SOURCE" -Description "Archivos identicos detectados." -Severity "MEDIUM" -EvidenceScope "hash: $($set.Name.Substring(0,12))..." -Evidence $fileList
        Show-Fail "[DUPLICADO] $fileList"
    }
} else {
    Add-Pass "[LIMPIEZA] Cero archivos fuente duplicados no autorizados."
}
