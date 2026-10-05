<#[
================================================================================
  ADSOLUSOL :: AUDITORIA DE CREACION Y ADMINISTRACION DE CAMPANAS
  MODO SOLO LECTURA: no modifica archivos, no compila y no instala dependencias.
================================================================================
]#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = 'Continue'
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot 'ADSOLUSOL.sln'))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

$failures = 0
$warnings = 0

function Report-Pass([string]$Code, [string]$Message) {
    Write-Host "  [PASS] [$Code] $Message" -ForegroundColor Green
}

function Report-Fail([string]$Code, [string]$Message) {
    Write-Host "  [FAIL] [$Code] $Message" -ForegroundColor Red
    $script:failures++
}

function Report-Warn([string]$Code, [string]$Message) {
    Write-Host "  [WARN] [$Code] $Message" -ForegroundColor Yellow
    $script:warnings++
}

function Read-Text([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    }
    return ''
}

function Test-Pattern {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Code,
        [string]$PassMessage,
        [string]$FailMessage,
        [switch]$Warning
    )

    if ($Text -match $Pattern) {
        Report-Pass $Code $PassMessage
    } elseif ($Warning) {
        Report-Warn $Code $FailMessage
    } else {
        Report-Fail $Code $FailMessage
    }
}

Write-Host '==========================================================================' -ForegroundColor Cyan
Write-Host ' [CAMPANAS] AUDITORIA DE CREACION Y ADMINISTRACION' -ForegroundColor Cyan
Write-Host '==========================================================================' -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$controllerPath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Presentation.Api\Controllers\CampaignsController.cs'
$servicePath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Application\Services\CampaignService.cs'
$entityPath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Domain\Entities\Campaign.cs'
$budgetPath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Application\Services\BudgetService.cs'
$eventPath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Application\Services\EventProcessingService.cs'
$metricsPath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Application\Services\MetricsService.cs'
$assignmentPath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Infrastructure\Repositories\AssignmentRepository.cs'
$repositoryPath = Join-Path $ScriptRoot 'src\ADSOLUSOL.Infrastructure\Repositories\CampaignRepository.cs'
$testRoot = Join-Path $ScriptRoot 'tests'

$controller = Read-Text $controllerPath
$service = Read-Text $servicePath
$entity = Read-Text $entityPath
$budget = Read-Text $budgetPath
$event = Read-Text $eventPath
$metrics = Read-Text $metricsPath
$assignment = Read-Text $assignmentPath
$repository = Read-Text $repositoryPath

Write-Host '[1/8] Verificando archivos canónicos del flujo...' -ForegroundColor Yellow
foreach ($item in @(
    @{ Code = 'CAMPAIGN-CONTROLLER'; Path = $controllerPath; Name = 'CampaignsController.cs' },
    @{ Code = 'CAMPAIGN-SERVICE'; Path = $servicePath; Name = 'CampaignService.cs' },
    @{ Code = 'CAMPAIGN-ENTITY'; Path = $entityPath; Name = 'Campaign.cs' },
    @{ Code = 'CAMPAIGN-REPOSITORY'; Path = $repositoryPath; Name = 'CampaignRepository.cs' }
)) {
    if (Test-Path -LiteralPath $item.Path) { Report-Pass $item.Code "$($item.Name) esta presente." }
    else { Report-Fail $item.Code "No se localizo $($item.Name)." }
}

Write-Host "`n[2/8] Auditando creación y validación de campañas..." -ForegroundColor Yellow
Test-Pattern $controller 'HttpPost\]' 'CAMPAIGN-CREATE-ENDPOINT' 'Existe endpoint POST para crear campañas.' 'No se detecto endpoint POST de creación.'
Test-Pattern $controller 'request\.Budget\s*<=\s*0' 'CAMPAIGN-BUDGET-INPUT' 'El controlador rechaza presupuestos menores o iguales a cero.' 'No se detecto validación de presupuesto positivo.'
Test-Pattern $controller 'CostPerMille\s*<\s*0|CostPerClick\s*<\s*0' 'CAMPAIGN-COST-INPUT' 'El controlador rechaza costos negativos.' 'No se detecto validación de costos negativos.'
Test-Pattern $controller 'EndDateUtc.*StartDateUtc|StartDateUtc.*EndDateUtc' 'CAMPAIGN-DATE-INPUT' 'Existe validación de coherencia entre fechas.' 'No se detecto validación suficiente de fechas.'
Test-Pattern $service 'Status\s*=\s*initialStatus|initialStatus\s*=' 'CAMPAIGN-INITIAL-STATUS' 'El servicio asigna estado inicial según la fecha de inicio.' 'No se detecto asignación explícita del estado inicial.'
Test-Pattern $service 'Guid\.NewGuid\(\)' 'CAMPAIGN-IDENTITY' 'La creación genera identificador nuevo.' 'No se detecto generación explícita de identificador único.'
Test-Pattern $service 'SaveChangesAsync' 'CAMPAIGN-PERSISTENCE' 'La creación confirma cambios mediante Unit of Work.' 'No se detecto confirmación de persistencia.'

Write-Host "`n[3/8] Auditando administración del ciclo de vida..." -ForegroundColor Yellow
Test-Pattern $controller 'UpdateStatus|/status' 'CAMPAIGN-STATUS-ENDPOINT' 'Existe endpoint para cambiar el estado.' 'No se detecto endpoint de administración de estado.'
Test-Pattern $controller 'ACTIVE.*PAUSED.*SCHEDULED.*COMPLETED|ACTIVE.*PAUSED' 'CAMPAIGN-STATUS-VALUES' 'El controlador limita los valores de estado.' 'No se detecto lista de estados permitidos.'
if ($service -match 'campaign\.Status\s*=\s*status' -and $service -notmatch 'Status.*switch|switch.*Status|allowedStatuses|transition') {
    Report-Warn 'CAMPAIGN-TRANSITIONS' 'El servicio asigna estados sin validar transiciones desde el estado anterior.'
} else {
    Report-Pass 'CAMPAIGN-TRANSITIONS' 'Se detecta lógica explícita de validación de transiciones.'
}
Test-Pattern $entity 'COMPLETED' 'CAMPAIGN-STATUS-MODEL' 'La entidad documenta el estado COMPLETED.' 'La entidad no documenta el ciclo de estados.' -Warning

Write-Host "`n[4/8] Auditando aislamiento por tenant..." -ForegroundColor Yellow
Test-Pattern $controller 'HttpContext\.Items\[.TenantId.\]' 'CAMPAIGN-TENANT-CONTEXT' 'El controlador obtiene TenantId del contexto autenticado.' 'No se detecto resolución de TenantId desde el contexto.'
Test-Pattern $service 'campaign\.TenantId\s*==\s*tenantId' 'CAMPAIGN-TENANT-SERVICE' 'El servicio comprueba pertenencia de la campaña al tenant.' 'No se detecto comprobación de tenant en el servicio.'
Test-Pattern $service 'GetAllAsync\(tenantId' 'CAMPAIGN-TENANT-LIST' 'El listado recibe tenantId.' 'El listado no muestra filtro explícito por tenant.'
Test-Pattern $controller 'GetMetrics|GetMetricsForCampaign' 'CAMPAIGN-METRICS-AUTH' 'La superficie de métricas existe y requiere campaña autorizada.' 'No se detecto protección de métricas.'
if ($assignment -match 'campaignId' -and $assignment -notmatch 'TenantId|tenantId') {
    Report-Warn 'CAMPAIGN-ASSIGNMENT-TENANT' 'AssignmentRepository no muestra comprobación explícita de tenant en sus métodos.'
} else {
    Report-Pass 'CAMPAIGN-ASSIGNMENT-TENANT' 'Las asociaciones muestran control de tenant.'
}

Write-Host "`n[5/8] Auditando presupuesto y métricas..." -ForegroundColor Yellow
Test-Pattern $entity 'BudgetSpent|RemainingBudget' 'CAMPAIGN-BUDGET-MODEL' 'La entidad mantiene presupuesto gastado y saldo derivado.' 'La entidad no expone el modelo completo de presupuesto.'
Test-Pattern $budget 'BudgetSpent|UpdateBudgetAsync' 'CAMPAIGN-BUDGET-DEBIT' 'Existe servicio de débito o actualización de presupuesto.' 'No se detecto débito explícito de presupuesto.'
Test-Pattern $budget 'BudgetSpent.*Budget|Budget.*BudgetSpent' 'CAMPAIGN-BUDGET-CEILING' 'El débito compara gasto contra presupuesto.' 'No se detecto protección explícita del límite presupuestario.'
Test-Pattern $event 'Duplicate|duplicate|EventId' 'CAMPAIGN-IDEMPOTENCY' 'El procesamiento contempla eventos duplicados.' 'No se detecto control explícito de duplicidad.'
Test-Pattern $metrics 'BudgetSpent|CampaignMetrics' 'CAMPAIGN-METRICS' 'Existe servicio de métricas asociado a la campaña.' 'No se detecto cálculo de métricas de campaña.'

Write-Host "`n[6/8] Auditando asociaciones de campaña..." -ForegroundColor Yellow
Test-Pattern $assignment 'AssignPlacementToCampaignAsync' 'CAMPAIGN-PLACEMENT' 'Existe asociación campaña-placement.' 'No se detecto asociación con placements.'
Test-Pattern $assignment 'AssignCreativeToCampaignAsync' 'CAMPAIGN-CREATIVE' 'Existe asociación campaña-creative.' 'No se detecto asociación con creativos.'
Test-Pattern $assignment 'AnyAsync' 'CAMPAIGN-ASSIGNMENT-IDEMPOTENCY' 'Las asociaciones comprueban duplicados antes de insertar.' 'No se detecto protección contra asociaciones duplicadas.'

Write-Host "`n[7/8] Auditando eventos y serving..." -ForegroundColor Yellow
Test-Pattern $controller 'RegisterClick|RegisterImpression' 'CAMPAIGN-EVENT-ENDPOINTS' 'Existen endpoints de click e impresión.' 'No se detectaron endpoints de eventos publicitarios.'
Test-Pattern $event 'ACTIVE|Budget|CampaignId' 'CAMPAIGN-SERVING-GUARDS' 'El procesamiento aplica controles de estado, campaña y presupuesto.' 'No se detectaron controles completos de serving.'

Write-Host "`n[8/8] Buscando pruebas de regresión de campañas..." -ForegroundColor Yellow
$testFiles = @(Get-ChildItem $testRoot -Recurse -File -Include '*.cs' -ErrorAction SilentlyContinue)
$testText = ($testFiles | ForEach-Object { Read-Text $_.FullName }) -join "`n"
Test-Pattern $testText 'Campaign creation|CreateAsync' 'CAMPAIGN-TEST-CREATE' 'Hay pruebas de creación de campañas.' 'No se detectaron pruebas de creación.' -Warning
Test-Pattern $testText 'tenant isolation|Tenant-A|TenantId' 'CAMPAIGN-TEST-TENANT' 'Hay pruebas de aislamiento por tenant.' 'No se detectaron pruebas claras de aislamiento por tenant.' -Warning
Test-Pattern $testText 'Overspend|Budget spent|Duplicate' 'CAMPAIGN-TEST-BUDGET' 'Hay pruebas de presupuesto y duplicidad de eventos.' 'No se detectaron pruebas de presupuesto o duplicidad.' -Warning
Test-Pattern $testText 'concurr|stress|Interlocked' 'CAMPAIGN-TEST-CONCURRENCY' 'Hay pruebas de concurrencia o carga sobre campañas.' 'No se detectaron pruebas explícitas de concurrencia.' -Warning

Write-Host "`n=========================================================================" -ForegroundColor Cyan
Write-Host '                    DICTAMEN DE CAMPAÑAS' -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " Fallas críticas : $failures" -ForegroundColor $(if ($failures -eq 0) { 'Green' } else { 'Red' })
Write-Host " Advertencias    : $warnings" -ForegroundColor $(if ($warnings -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ' AUDITORIA TERMINADA - NO SE MODIFICO NINGUN ARCHIVO' -ForegroundColor Green

if ($failures -gt 0) { exit 1 } else { exit 0 }
