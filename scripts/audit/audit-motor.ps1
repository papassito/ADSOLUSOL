<#[
  ADSOLUSOL :: AUDITOR DE MOTOR DE EJECUCION
  Solo lectura: inspecciona estructura, contratos y deuda tecnica del Motor.
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
$module = Join-Path $base 'src\ADSOLUSOL.Motor'
$fails = 0; $warns = 0
function Pass($code,$msg) { Write-Host "  [PASS] [$code] $msg" -ForegroundColor Green }
function Fail($code,$msg) { Write-Host "  [FAIL] [$code] $msg" -ForegroundColor Red; $script:fails++ }
function Warn($code,$msg) { Write-Host "  [WARN] [$code] $msg" -ForegroundColor Yellow; $script:warns++ }

Write-Host '===========================================================================' -ForegroundColor Cyan
Write-Host ' [MOTOR] AUDITORIA DEL MOTOR DE EJECUCION' -ForegroundColor Cyan
Write-Host "Directorio Base: $base`n" -ForegroundColor DarkGray
if (-not (Test-Path $module)) { Fail 'MOTOR-PATH' 'No se localizo src\ADSOLUSOL.Motor.'; exit 1 }

$files = @(Get-ChildItem $module -Recurse -File -Filter '*.cs')
$engine = @(Get-ChildItem (Join-Path $module 'Engine') -File -Filter '*.cs' -ErrorAction SilentlyContinue)
$strategies = @(Get-ChildItem (Join-Path $module 'Strategies') -File -Filter '*.cs' -ErrorAction SilentlyContinue)
if ($engine.Count -gt 0) { Pass 'MOTOR-ENGINE' "Engine contiene $($engine.Count) archivo(s) de ejecucion." } else { Fail 'MOTOR-ENGINE' 'No existe codigo en Engine.' }
if ($strategies.Count -gt 0) { Pass 'MOTOR-STRATEGY' "Strategies contiene $($strategies.Count) estrategia(s)." } else { Fail 'MOTOR-STRATEGY' 'No existe codigo en Strategies.' }
if ($files.Count -eq 0) { Fail 'MOTOR-CODE' 'El modulo no contiene archivos C#.' } else { Pass 'MOTOR-CODE' "Se inspeccionaron $($files.Count) archivos C#." }

$all = ($files | ForEach-Object { [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) }) -join "`n"
if ($all -match 'NotImplementedException|TODO|FIXME|throw\s+new\s+Exception\s*\(') { Warn 'MOTOR-DEBT' 'Se detecto deuda tecnica o excepcion generica en el Motor.' } else { Pass 'MOTOR-DEBT' 'No se detectaron stubs, TODO/FIXME ni excepciones genericas.' }
$large = @($files | Where-Object { (Get-Content $_.FullName).Count -gt 500 })
if ($large.Count -eq 0) { Pass 'MOTOR-SRP' 'Los archivos del Motor estan debajo de 500 lineas.' } else { Warn 'MOTOR-SRP' "$($large.Count) archivo(s) supera(n) 500 lineas." }
Write-Host "`nDictamen Motor: fallas=$fails advertencias=$warns" -ForegroundColor Cyan
if ($fails -gt 0) { exit 1 } else { exit 0 }
