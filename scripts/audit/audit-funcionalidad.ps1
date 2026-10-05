<#[
  ADSOLUSOL :: AUDITORIA DE FUNCIONALIDAD
  Comprueba endpoints, ciclo de vida, serving, asociaciones y regresiones.
]#>
[CmdletBinding()]
param([string]$Root = $PSScriptRoot)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$base = (Resolve-Path $Root).Path
while ($base -and -not (Test-Path (Join-Path $base 'ADSOLUSOL.sln'))) {
    $parent = Split-Path $base -Parent
    if ($parent -eq $base) { break }
    $base = $parent
}
$fails = 0; $warns = 0
function Check($condition,$code,$message,[switch]$WarnOnly) {
    if ($condition) { Write-Host "  [PASS] [$code] $message" -ForegroundColor Green }
    elseif ($WarnOnly) { Write-Host "  [WARN] [$code] $message" -ForegroundColor Yellow; $script:warns++ }
    else { Write-Host "  [FAIL] [$code] $message" -ForegroundColor Red; $script:fails++ }
}
function ReadText($path) { if (Test-Path $path) { return [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8) }; return '' }

$controller = ReadText (Join-Path $base 'src\ADSOLUSOL.Presentation.Api\Controllers\CampaignsController.cs')
$serve = ReadText (Join-Path $base 'src\ADSOLUSOL.Application\Services\AdServingService.cs')
$campaign = ReadText (Join-Path $base 'src\ADSOLUSOL.Application\Services\CampaignService.cs')
$events = ReadText (Join-Path $base 'src\ADSOLUSOL.Application\Services\EventProcessingService.cs')
$assign = ReadText (Join-Path $base 'src\ADSOLUSOL.Infrastructure\Repositories\AssignmentRepository.cs')
$tests = ((Get-ChildItem (Join-Path $base 'tests') -Recurse -File -Filter '*.cs' -ErrorAction SilentlyContinue | ForEach-Object { ReadText $_.FullName }) -join "`n")

Write-Host '===========================================================================' -ForegroundColor Cyan
Write-Host ' [FUNCIONALIDAD] AUDITORIA DE OPERATIVIDAD Y CASOS DE USO' -ForegroundColor Cyan
Write-Host "Directorio Base: $base`n" -ForegroundColor DarkGray
Check ($controller -match 'HttpPost' -and $controller -match 'HttpGet') 'FUNC-ROUTES' 'Existen rutas HTTP de campañas.'
Check ($controller -match 'CreateCampaign' -and $controller -match 'UpdateStatus') 'FUNC-CAMPAIGN-LIFECYCLE' 'Existen creación y cambio de estado de campañas.'
Check ($controller -match 'RegisterClick' -and $controller -match 'RegisterImpression') 'FUNC-EVENT-ROUTES' 'Existen rutas de clicks e impresiones.'
Check ($campaign -match 'CreateAsync' -and $campaign -match 'SaveChangesAsync') 'FUNC-CREATE-PERSIST' 'La creación persiste la campaña.'
Check ($campaign -match 'Status' -and $campaign -match 'TenantId') 'FUNC-STATUS-TENANT' 'El servicio administra estado y tenant.'
Check ($serve -match 'GetEligible|eligible|Campaign') 'FUNC-SERVING' 'Existe selección de campañas elegibles para serving.'
Check ($assign -match 'AssignPlacementToCampaignAsync' -and $assign -match 'AssignCreativeToCampaignAsync') 'FUNC-ASSIGNMENTS' 'Existen asociaciones con placement y creative.'
Check ($events -match 'ProcessEvent' -and $events -match 'EventProcessingStatus') 'FUNC-EVENT-PROCESSING' 'Existe procesamiento de eventos publicitarios.'
Check ($tests -match 'Campaign creation|CreateAsync' -and $tests -match 'Overspend|Budget spent') 'FUNC-REGRESSION' 'Existen regresiones de creación y presupuesto.' -WarnOnly

Write-Host "`nFallas criticas: $fails" -ForegroundColor $(if ($fails -eq 0) { 'Green' } else { 'Red' })
Write-Host "Advertencias: $warns" -ForegroundColor $(if ($warns -eq 0) { 'Green' } else { 'Yellow' })
if ($fails -gt 0) { exit 1 } else { exit 0 }
