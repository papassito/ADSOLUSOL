<#[
  ADSOLUSOL :: AUDITOR DE PRESENTACION WEB
  Solo lectura: inspecciona estructura React/Vite, archivos grandes y deuda tecnica.
]#>
[CmdletBinding()]
param([string]$Root = $PSScriptRoot)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$base = (Resolve-Path $Root).Path
while ($base -and -not (Test-Path (Join-Path $base 'ADSOLUSOL.sln'))) {
    $parent = Split-Path $base -Parent
    if ($parent -eq $base) { break }
    $base = $parent
}
$module = Join-Path $base 'src\ADSOLUSOL.Presentation.Web'
$fails = 0; $warns = 0
function Pass($code,$msg) { Write-Host "  [PASS] [$code] $msg" -ForegroundColor Green }
function Fail($code,$msg) { Write-Host "  [FAIL] [$code] $msg" -ForegroundColor Red; $script:fails++ }
function Warn($code,$msg) { Write-Host "  [WARN] [$code] $msg" -ForegroundColor Yellow; $script:warns++ }

Write-Host '===========================================================================' -ForegroundColor Cyan
Write-Host ' [WEB] AUDITORIA DE PRESENTACION WEB' -ForegroundColor Cyan
Write-Host "Directorio Base: $base`n" -ForegroundColor DarkGray
if (-not (Test-Path $module)) { Fail 'WEB-PATH' 'No se localizo src\ADSOLUSOL.Presentation.Web.'; exit 1 }

$package = Join-Path $module 'package.json'
$src = Join-Path $module 'src'
if (Test-Path $package) { Pass 'WEB-PACKAGE' 'package.json esta presente.' } else { Fail 'WEB-PACKAGE' 'Falta package.json.' }
if (Test-Path $src) { Pass 'WEB-SRC' 'Directorio src esta presente.' } else { Fail 'WEB-SRC' 'Falta el directorio src.' }
$code = @(Get-ChildItem $src -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.ts','.tsx','.js','.jsx','.css' })
if ($code.Count -eq 0) { Fail 'WEB-CODE' 'No se detectaron archivos de frontend.' } else { Pass 'WEB-CODE' "Se inspeccionaron $($code.Count) archivos de frontend." }
$app = Join-Path $src 'App.tsx'
if (Test-Path $app) {
    $appLines = (Get-Content $app).Count
    if ($appLines -gt 800) { Warn 'WEB-SRP' "App.tsx tiene $appLines lineas; requiere division por componentes." } else { Pass 'WEB-SRP' "App.tsx tiene $appLines lineas." }
} else { Warn 'WEB-ENTRY' 'No se encontro App.tsx; verificar el punto de entrada manualmente.' }
$all = ($code | ForEach-Object { [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) }) -join "`n"
if ($all -match '\bTODO\b|\bFIXME\b|NotImplementedException') { Warn 'WEB-DEBT' 'Se detectaron TODO/FIXME o implementaciones incompletas.' } else { Pass 'WEB-DEBT' 'No se detectaron TODO/FIXME ni implementaciones incompletas.' }
$empty = @($code | Where-Object Length -eq 0)
if ($empty.Count -eq 0) { Pass 'WEB-EMPTY' 'No hay archivos de frontend vacios.' } else { Fail 'WEB-EMPTY' "$($empty.Count) archivo(s) de frontend tienen cero bytes." }
Write-Host "`nDictamen Web: fallas=$fails advertencias=$warns" -ForegroundColor Cyan
if ($fails -gt 0) { exit 1 } else { exit 0 }
