<#
 .SYNOPSIS
     Detecta duplicados exactos del proyecto y, opcionalmente, los elimina.

 .DESCRIPTION
     El modo predeterminado es solo lectura. Los duplicados se determinan por
     hash SHA-256 y se excluyen las carpetas generadas por compilación.

 .PARAMETER Apply
     Elimina los duplicados exactos encontrados, conservando el primero.

 .PARAMETER ReportPath
     Ruta opcional para guardar el inventario en texto.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Apply,
    [string]$ReportPath = ".\_audit\duplicates.txt"
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $PSScriptRoot).Path
$excluded = '[\\/](\.git|bin|obj|node_modules|dist|build|coverage|_audit)[\\/]'
$protectedExtensions = @(".csproj", ".sln", ".slnx", ".props", ".targets")

$files = Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object { $_.FullName -notmatch $excluded }

$groups = @{}
foreach ($file in $files) {
    # Archivos de proyecto pueden compartir contenido y aun así tener
    # identidad semántica distinta por su ubicación y nombre.
    if ($protectedExtensions -contains $file.Extension.ToLowerInvariant()) {
        continue
    }
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    if (-not $groups.ContainsKey($hash)) {
        $groups[$hash] = [System.Collections.Generic.List[object]]::new()
    }
    $groups[$hash].Add($file)
}

$duplicates = @($groups.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 })
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("INVENTARIO DE DUPLICADOS EXACTOS CANDIDATOS")
$lines.Add("Raiz: $root")
$lines.Add("Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("Modo: $(if ($Apply) { 'APLICAR' } else { 'SOLO LECTURA' })")
$lines.Add("")

if ($duplicates.Count -eq 0) {
    $lines.Add("No se encontraron duplicados exactos candidatos.")
    Write-Host "[PASS] No se encontraron duplicados exactos candidatos." -ForegroundColor Green
}
else {
    foreach ($group in $duplicates) {
        $ordered = @($group.Value | Sort-Object FullName)
        $canonical = $ordered[0]
        $lines.Add("HASH $($group.Key)")
        $lines.Add("  CONSERVAR: $($canonical.FullName)")

        foreach ($duplicate in ($ordered | Select-Object -Skip 1)) {
            $lines.Add("  DUPLICADO:  $($duplicate.FullName)")
            if ($Apply -and $PSCmdlet.ShouldProcess($duplicate.FullName, "Eliminar duplicado exacto")) {
                Remove-Item -LiteralPath $duplicate.FullName -Force
                Write-Host "[DELETE] $($duplicate.FullName)" -ForegroundColor Yellow
            }
        }
        $lines.Add("")
    }
    Write-Host "[INFO] Grupos duplicados candidatos encontrados: $($duplicates.Count)" -ForegroundColor Cyan
    if (-not $Apply) {
        Write-Host "[INFO] Ejecuta con -Apply para eliminar conservando el primer archivo." -ForegroundColor Yellow
    }
}

$reportFullPath = Join-Path $root $ReportPath
$reportDirectory = Split-Path -Parent $reportFullPath
if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
}
[System.IO.File]::WriteAllLines($reportFullPath, $lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "[REPORT] $reportFullPath" -ForegroundColor DarkGray
