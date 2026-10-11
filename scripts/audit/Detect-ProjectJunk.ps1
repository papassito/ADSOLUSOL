<#
.SYNOPSIS
    Detecta residuos y archivos sospechosos del proyecto.

.DESCRIPTION
    Auditoría de solo lectura. No elimina archivos. Revisa temporales,
    residuos de editores, archivos del sistema, volcados, binarios sueltos
    y archivos vacíos fuera de carpetas generadas.
#>
[CmdletBinding()]
param(
    [string]$ReportPath = ".\_audit\project_junk.txt"
)

$ErrorActionPreference = "Stop"
$scriptDir = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $PSScriptRoot } else { (Get-Location).Path }
$root = (Resolve-Path $scriptDir).Path
while ($root -and -not (Test-Path (Join-Path $root "ADSOLUSOL.sln"))) {
    $parent = Split-Path $root -Parent
    if ($parent -eq $root) { break }
    $root = $parent
}
Set-Location $root
$excluded = '[\\/](\.git|bin|obj|node_modules|dist|build|coverage|_audit)[\\/]'
$junkNames = @(
    ".DS_Store", "Thumbs.db", "desktop.ini", "ehthumbs.db",
    "nul", "CON", "._*"
)
$junkExtensions = @(
    ".tmp", ".temp", ".bak", ".old", ".orig", ".rej", ".swp", ".swo",
    ".dmp", ".crash", ".log~", ".pid", ".cache"
)
$junkPatterns = @(
    ".*~", "*.tmp", "*.temp", "*.bak", "*.old", "*.orig", "*.rej",
    "*.swp", "*.swo", "*.dmp", "*.crash"
)

$files = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch $excluded }

$findings = [System.Collections.Generic.List[object]]::new()
foreach ($file in $files) {
    $reason = $null
    if ($file.Length -eq 0) {
        $reason = "ARCHIVO VACIO"
    }
    elseif ($junkNames -contains $file.Name -or $file.Name -like "._*") {
        $reason = "ARCHIVO DEL SISTEMA"
    }
    elseif ($junkExtensions -contains $file.Extension.ToLowerInvariant()) {
        $reason = "EXTENSION TEMPORAL"
    }
    elseif ($file.Name -match '(^|[._-])(backup|bak|copy|copia|old|temp|tmp|test[-_]?data)([._-]|$)') {
        $reason = "NOMBRE SOSPECHOSO"
    }
    elseif ($file.Name -match '(^|[._-])(core|crash|dump)\b') {
        $reason = "VOLCADO O CRASH"
    }

    if ($reason) {
        $findings.Add([pscustomobject]@{
            Reason = $reason
            Size = $file.Length
            Path = $file.FullName
        })
    }
}

$reportFullPath = Join-Path $root $ReportPath
$reportDirectory = Split-Path -Parent $reportFullPath
if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("AUDITORIA DE BASURA DEL PROYECTO")
$lines.Add("Raiz: $root")
$lines.Add("Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("Modo: SOLO LECTURA")
$lines.Add("")

if ($findings.Count -eq 0) {
    $lines.Add("No se detectaron residuos sospechosos.")
    Write-Host "[PASS] No se detectó basura del proyecto." -ForegroundColor Green
}
else {
    foreach ($finding in ($findings | Sort-Object Reason, Path)) {
        $relative = $finding.Path.Substring($root.Length).TrimStart("\")
        $lines.Add(("[{0}] {1} bytes :: {2}" -f $finding.Reason, $finding.Size, $relative))
    }
    Write-Host "[WARN] Hallazgos detectados: $($findings.Count)" -ForegroundColor Yellow
}

[System.IO.File]::WriteAllLines($reportFullPath, $lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "[REPORT] $reportFullPath" -ForegroundColor DarkGray
if ($findings.Count -gt 0) { exit 1 } else { exit 0 }
