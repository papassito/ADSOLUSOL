<#
.SYNOPSIS
    Detecta riesgos que podrían quedar fuera de la suite de auditoría.

.DESCRIPTION
    Auditoría complementaria de solo lectura. Busca superficies no cubiertas,
    scripts no registrados, fuentes fuera de módulos, deuda textual e imports
    web no resolubles.
#>
[CmdletBinding()]
param(
    [string]$MasterPath = ".\scripts\audit\audit_all_project.ps1",
    [string]$OutputPath = ".\_audit\audit_false_negatives.txt"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $PSScriptRoot).Path
$masterFullPath = Join-Path $root $MasterPath
$outputFullPath = Join-Path $root $OutputPath
$findings = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $masterFullPath)) {
    Write-Error "No existe la suite master: $masterFullPath"
}

$master = Get-Content -LiteralPath $masterFullPath -Raw
$auditDir = Join-Path $root "scripts\audit"
$registered = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($m in [regex]::Matches($master, 'Script\s*=\s*"[^"]+\\([^"\\]+\.ps1)"')) {
    [void]$registered.Add($m.Groups[1].Value)
}

# Scripts de auditoría existentes que no aparecen en la suite master.
foreach ($script in Get-ChildItem -LiteralPath $auditDir -Filter "*.ps1" -File) {
    if ($script.Name -notin @("audit_all_project.ps1") -and -not $registered.Contains($script.Name)) {
        $findings.Add("AUDITOR NO REGISTRADO EN SUITE MASTER: scripts\audit\$($script.Name)")
    }
}

# Proyectos .NET sin referencia en la solución.
$solution = Get-ChildItem -LiteralPath $root -Filter "*.sln" -File | Select-Object -First 1
if ($solution) {
    $solutionText = Get-Content -LiteralPath $solution.FullName -Raw
    foreach ($project in Get-ChildItem -LiteralPath (Join-Path $root "src") -Recurse -Filter "*.csproj" -File) {
        $relative = $project.FullName.Substring($root.Length + 1).Replace("\", "/")
        $name = $project.Name
        if ($solutionText -notmatch [regex]::Escape($name) -and $solutionText -notmatch [regex]::Escape($relative)) {
            $findings.Add("PROYECTO NO REFERENCIADO EN SOLUCION: $relative")
        }
    }
}

# Deuda o marcadores que otros auditores podrían no contar.
$sourceRoots = @("src", "tests")
foreach ($sourceRoot in $sourceRoots) {
    $path = Join-Path $root $sourceRoot
    if (-not (Test-Path -LiteralPath $path)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $path -Recurse -File -Include "*.cs","*.csproj","*.ts","*.tsx","*.js","*.jsx","*.ps1") {
        if ($file.FullName -match '[\\/](bin|obj|node_modules|dist|build|coverage|\.git)[\\/]') { continue }
        $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($text -match '(?im)\b(TODO|FIXME|XXX|HACK)\b') {
            $findings.Add("DEUDA NO RESUELTA DETECTADA: $($file.FullName.Substring($root.Length + 1))")
        }
        if ($file.Length -eq 0) {
            $findings.Add("ARCHIVO DE FUENTE VACIO: $($file.FullName.Substring($root.Length + 1))")
        }
    }
}

# Imports relativos del frontend que no resuelven a ningún archivo.
$webRoot = Join-Path $root "src\ADSOLUSOL.Presentation.Web\src"
if (Test-Path -LiteralPath $webRoot) {
    foreach ($file in Get-ChildItem -LiteralPath $webRoot -Recurse -File -Include "*.ts","*.tsx","*.js","*.jsx") {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($match in [regex]::Matches($text, "(?:from|import)\s*\(?\s*['""](\.[^'""]+)['""]")) {
            $base = Join-Path $file.DirectoryName $match.Groups[1].Value
            $resolved = @("$base.ts","$base.tsx","$base.js","$base.jsx","$base.json",$base) |
                Where-Object { Test-Path -LiteralPath $_ }
            if (-not $resolved) {
                $findings.Add("IMPORT WEB NO RESUELTO: $($file.Name) -> $($match.Groups[1].Value)")
            }
        }
    }
}

# Archivos de configuración o contratos sin contenido.
foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Include "*.json","*.csproj","*.props","*.targets") {
    if ($file.FullName -match '[\\/](bin|obj|node_modules|dist|build|coverage|\.git|_audit)[\\/]') { continue }
    if ($file.Length -eq 0) {
        $findings.Add("CONFIGURACION VACIA: $($file.FullName.Substring($root.Length + 1))")
    }
}

$outputDirectory = Split-Path -Parent $outputFullPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("DETECCION DE FALSOS NEGATIVOS DE AUDITORIA")
$lines.Add("Raiz: $root")
$lines.Add("Suite analizada: $masterFullPath")
$lines.Add("Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("Modo: SOLO LECTURA")
$lines.Add("")
$lines.Add("RIESGOS POTENCIALMENTE OMITIDOS: $($findings.Count)")
foreach ($finding in ($findings | Sort-Object -Unique)) {
    $lines.Add("  [REVISAR] $finding")
}
if ($findings.Count -eq 0) {
    $lines.Add("No se detectaron superficies omitidas con estas comprobaciones.")
}

[System.IO.File]::WriteAllLines($outputFullPath, $lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "[REPORT] $outputFullPath" -ForegroundColor DarkGray
Write-Host "[INFO] Riesgos potencialmente omitidos: $($findings.Count)" -ForegroundColor Cyan
if ($findings.Count -gt 0) { exit 1 } else { exit 0 }
