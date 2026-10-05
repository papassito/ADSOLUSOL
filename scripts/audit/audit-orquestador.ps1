<#[
  ADSOLUSOL :: AUDITOR DE ORQUESTACION
  Solo lectura: inspecciona coordinadores, flujos y acoplamientos indebidos.
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
$module = Join-Path $base 'src\ADSOLUSOL.Orchestrator'
$fails = 0; $warns = 0
function Pass($code,$msg) { Write-Host "  [PASS] [$code] $msg" -ForegroundColor Green }
function Fail($code,$msg) { Write-Host "  [FAIL] [$code] $msg" -ForegroundColor Red; $script:fails++ }
function Warn($code,$msg) { Write-Host "  [WARN] [$code] $msg" -ForegroundColor Yellow; $script:warns++ }

Write-Host '===========================================================================' -ForegroundColor Cyan
Write-Host ' [ORQUESTADOR] AUDITORIA DE COORDINACION Y FLUJOS' -ForegroundColor Cyan
Write-Host "Directorio Base: $base`n" -ForegroundColor DarkGray
if (-not (Test-Path $module)) { Fail 'ORCH-PATH' 'No se localizo src\ADSOLUSOL.Orchestrator.'; exit 1 }

$files = @(Get-ChildItem $module -Recurse -File -Filter '*.cs')
$coordinators = @(Get-ChildItem (Join-Path $module 'Coordinators') -File -Filter '*.cs' -ErrorAction SilentlyContinue)
$flows = @(Get-ChildItem (Join-Path $module 'Flows') -File -Filter '*.cs' -ErrorAction SilentlyContinue)
if ($coordinators.Count -gt 0) { Pass 'ORCH-COORD' "Coordinators contiene $($coordinators.Count) archivo(s)." } else { Fail 'ORCH-COORD' 'No existe codigo en Coordinators.' }
if ($flows.Count -gt 0) { Pass 'ORCH-FLOWS' "Flows contiene $($flows.Count) flujo(s)." } else { Fail 'ORCH-FLOWS' 'No existe codigo en Flows.' }
if ($files.Count -eq 0) { Fail 'ORCH-CODE' 'El modulo no contiene archivos C#.' } else { Pass 'ORCH-CODE' "Se inspeccionaron $($files.Count) archivos C#." }

$all = ($files | ForEach-Object { [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) }) -join "`n"
if ($all -match 'using\s+ADSOLUSOL\.Infrastructure\b') { Fail 'ORCH-COUPLING' 'El Orchestrator referencia Infrastructure concreta.' } else { Pass 'ORCH-COUPLING' 'No se detecto acoplamiento directo a Infrastructure.' }
if ($all -match 'NotImplementedException|TODO|FIXME|throw\s+new\s+Exception\s*\(') { Warn 'ORCH-DEBT' 'Se detecto deuda tecnica o excepcion generica en la orquestacion.' } else { Pass 'ORCH-DEBT' 'No se detectaron stubs, TODO/FIXME ni excepciones genericas.' }
Write-Host "`nDictamen Orchestrator: fallas=$fails advertencias=$warns" -ForegroundColor Cyan
if ($fails -gt 0) { exit 1 } else { exit 0 }
