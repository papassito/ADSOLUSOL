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
$fail = 0; $warn = 0
function Pass($c,$m) { Write-Host "  [PASS] [$c] $m" -ForegroundColor Green }
function Fail($c,$m) { Write-Host "  [FAIL] [$c] $m" -ForegroundColor Red; $script:fail++ }
function Warn($c,$m) { Write-Host "  [WARN] [$c] $m" -ForegroundColor Yellow; $script:warn++ }
function Text($p) { if (Test-Path $p) { return [IO.File]::ReadAllText($p,[Text.Encoding]::UTF8) }; return '' }
function Check($t,$r,$c,$ok,$bad,[switch]$Warning) {
    if ($t -match $r) { Pass $c $ok } elseif ($Warning) { Warn $c $bad } else { Fail $c $bad }
}

Write-Host '===========================================================================' -ForegroundColor Cyan
Write-Host ' [CAMPANAS] AUDITORIA DE CREACION Y ADMINISTRACION' -ForegroundColor Cyan
Write-Host "Directorio Base: $base`n" -ForegroundColor DarkGray

$controller = Text (Join-Path $base 'src\ADSOLUSOL.Presentation.Api\Controllers\CampaignsController.cs')
$service = Text (Join-Path $base 'src\ADSOLUSOL.Application\Services\CampaignService.cs')
$entity = Text (Join-Path $base 'src\ADSOLUSOL.Domain\Entities\Campaign.cs')
$budget = Text (Join-Path $base 'src\ADSOLUSOL.Application\Services\BudgetService.cs')
$events = Text (Join-Path $base 'src\ADSOLUSOL.Application\Services\EventProcessingService.cs')
$metrics = Text (Join-Path $base 'src\ADSOLUSOL.Application\Services\MetricsService.cs')
$assign = Text (Join-Path $base 'src\ADSOLUSOL.Infrastructure\Repositories\AssignmentRepository.cs')
$repo = Text (Join-Path $base 'src\ADSOLUSOL.Infrastructure\Repositories\CampaignRepository.cs')
$tests = ((Get-ChildItem (Join-Path $base 'tests') -Recurse -File -Filter '*.cs' -ErrorAction SilentlyContinue | ForEach-Object { Text $_.FullName }) -join "`n")

Write-Host '[1/7] Creacion y persistencia' -ForegroundColor Yellow
Check $controller 'HttpPost\]' 'CAMPAIGN-CREATE' 'Existe POST de campanas.' 'No existe POST de campanas.'
Check $controller 'Budget\s*<=\s*0' 'CAMPAIGN-BUDGET-INPUT' 'Valida presupuesto positivo.' 'No valida presupuesto positivo.'
Check $controller 'CostPerMille\s*<\s*0|CostPerClick\s*<\s*0' 'CAMPAIGN-COST-INPUT' 'Rechaza costos negativos.' 'No rechaza costos negativos.'
Check $controller 'EndDateUtc.*StartDateUtc|StartDateUtc.*EndDateUtc' 'CAMPAIGN-DATES' 'Valida rango de fechas.' 'No valida rango de fechas.'
Check $service 'Guid\.NewGuid\(\)' 'CAMPAIGN-ID' 'Genera identificador nuevo.' 'No genera identificador explícito.'
Check $service 'SaveChangesAsync' 'CAMPAIGN-SAVE' 'Confirma persistencia.' 'No confirma persistencia.'

Write-Host '[2/7] Ciclo de vida' -ForegroundColor Yellow
Check $controller 'UpdateStatus|/status' 'CAMPAIGN-STATUS-API' 'Tiene API de cambio de estado.' 'No tiene API de cambio de estado.'
Check $controller 'ACTIVE.*PAUSED.*SCHEDULED.*COMPLETED|ACTIVE.*PAUSED' 'CAMPAIGN-STATUS-VALUES' 'Limita estados permitidos.' 'No limita estados permitidos.'
if ($service -match 'campaign\.Status\s*=\s*status' -and $service -notmatch 'switch|transition|allowedStatuses') { Warn 'CAMPAIGN-TRANSITIONS' 'El servicio no valida transiciones desde el estado anterior.' } else { Pass 'CAMPAIGN-TRANSITIONS' 'Se detecta validacion de transiciones.' }

Write-Host '[3/7] Tenant y autorizacion' -ForegroundColor Yellow
Check $controller 'HttpContext\.Items\[.TenantId.\]' 'CAMPAIGN-TENANT-CONTEXT' 'Obtiene tenant del contexto.' 'No obtiene tenant del contexto.'
Check $service 'TenantId\s*==\s*tenantId' 'CAMPAIGN-TENANT-SERVICE' 'Comprueba pertenencia al tenant.' 'No comprueba pertenencia al tenant.'
Check $service 'GetAllAsync\(tenantId' 'CAMPAIGN-TENANT-LIST' 'Lista por tenant.' 'No lista explícitamente por tenant.'
if ($assign -match 'campaignId' -and $assign -notmatch 'TenantId|tenantId') { Warn 'CAMPAIGN-ASSIGNMENT-TENANT' 'Las asociaciones no muestran comprobacion explícita de tenant.' } else { Pass 'CAMPAIGN-ASSIGNMENT-TENANT' 'Las asociaciones muestran control de tenant.' }

Write-Host '[4/7] Presupuesto y metricas' -ForegroundColor Yellow
Check $entity 'BudgetSpent|RemainingBudget' 'CAMPAIGN-BUDGET-MODEL' 'Modela gasto y saldo.' 'No modela gasto y saldo.'
Check $budget 'BudgetSpent|UpdateBudgetAsync' 'CAMPAIGN-BUDGET-DEBIT' 'Tiene debito de presupuesto.' 'No tiene debito de presupuesto.'
Check ($budget + $repo) 'BudgetSpent.*Budget|Budget.*BudgetSpent' 'CAMPAIGN-BUDGET-LIMIT' 'Compara gasto contra presupuesto.' 'No muestra limite presupuestario.'
Check $metrics 'BudgetSpent|CampaignMetrics' 'CAMPAIGN-METRICS' 'Calcula metricas de campaña.' 'No calcula metricas de campaña.'

Write-Host '[5/7] Eventos e idempotencia' -ForegroundColor Yellow
Check $events 'Duplicate|duplicate|EventId' 'CAMPAIGN-IDEMPOTENCY' 'Controla eventos duplicados.' 'No controla duplicados.'
Check $events 'ACTIVE|Budget|CampaignId' 'CAMPAIGN-EVENT-GUARDS' 'Aplica controles de estado, campaña y presupuesto.' 'No muestra controles de eventos.'
Check $controller 'RegisterClick|RegisterImpression' 'CAMPAIGN-EVENT-API' 'Expone click e impresion.' 'No expone eventos de campaña.'

Write-Host '[6/7] Placements y creativos' -ForegroundColor Yellow
Check $assign 'AssignPlacementToCampaignAsync' 'CAMPAIGN-PLACEMENT' 'Asocia placements.' 'No asocia placements.'
Check $assign 'AssignCreativeToCampaignAsync' 'CAMPAIGN-CREATIVE' 'Asocia creativos.' 'No asocia creativos.'
Check $assign 'AnyAsync' 'CAMPAIGN-ASSIGNMENT-DUPLICATES' 'Evita asociaciones duplicadas.' 'No evita asociaciones duplicadas.'

Write-Host '[7/7] Pruebas de regresion' -ForegroundColor Yellow
Check $tests 'Campaign creation|CreateAsync' 'CAMPAIGN-TEST-CREATE' 'Tiene prueba de creacion.' 'No tiene prueba de creacion.' -Warning
Check $tests 'tenant isolation|Tenant-A|TenantId' 'CAMPAIGN-TEST-TENANT' 'Tiene prueba de aislamiento.' 'No tiene prueba clara de aislamiento.' -Warning
Check $tests 'Overspend|Budget spent|Duplicate' 'CAMPAIGN-TEST-BUDGET' 'Tiene pruebas de presupuesto y duplicidad.' 'No tiene pruebas de presupuesto o duplicidad.' -Warning
Check $tests 'concurr|stress|Interlocked' 'CAMPAIGN-TEST-CONCURRENCY' 'Tiene prueba de concurrencia.' 'No tiene prueba explícita de concurrencia.' -Warning

Write-Host "`n=========================================================================" -ForegroundColor Cyan
Write-Host 'DICTAMEN DE CAMPANAS' -ForegroundColor Cyan
Write-Host "Fallas criticas: $fail" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Red' })
Write-Host "Advertencias: $warn" -ForegroundColor $(if ($warn -eq 0) { 'Green' } else { 'Yellow' })
Write-Host 'AUDITORIA TERMINADA - SOLO LECTURA' -ForegroundColor Green
if ($fail -gt 0) { exit 1 } else { exit 0 }
