$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = if ($scriptDir) { Split-Path -Parent $scriptDir } else { $pwd.Path }
$docs = Join-Path $root 'docs'
$files = @(Get-Item -LiteralPath (Join-Path $root 'README.md')) + @(Get-ChildItem -LiteralPath $docs -Recurse -File | Where-Object { $_.Name -ne 'MANIFEST.md' } | Sort-Object FullName)
$lines = @('# AD SOLUSOL - Manifest documental', '', 'Generado por `scripts/update_manifest.ps1`. Rutas relativas a la raiz del proyecto.', '', "**Files:** $($files.Count)", '', '| File | SHA-256 |', '|---|---|')
foreach ($file in $files) {
    $path = $file.FullName.Substring($root.Length + 1).Replace('\','/')
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    $lines += '| `' + $path + '` | `' + $hash + '` |'
}
Set-Content -LiteralPath (Join-Path $docs 'MANIFEST.md') -Value $lines -Encoding utf8
Write-Output "Manifest updated: $($files.Count) documents."
