<#
================================================================================
  ADSOLUSOL :: AUDITORIA PERICIAL DE LOGICA Y REGLAS DE NEGOCIO (NASA GRADE)
  Fiscaliza el algoritmo de pacing/ranking, máquina de estados de campaña,
  fórmulas de tarificación, deduplicación temprana e invariantes de balance.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [LOGICA] AUDITORIA DE REGLAS DE DECISION Y ALGORITMOS (NASA GRADE)       " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$logicaFails = 0
$logicaWarns = 0

function Assert-Logic([bool]$Condition, [string]$Code, [string]$Message, [bool]$IsFatal = $true) {
    if ($Condition) {
        Write-Host "  [PASS] [$Code] $Message" -ForegroundColor Green
    } else {
        if ($IsFatal) {
            Write-Host "  [FAIL] [$Code] $Message" -ForegroundColor Red
            $script:logicaFails++
        } else {
            Write-Host "  [WARN] [$Code] $Message" -ForegroundColor Yellow
            $script:logicaWarns++
        }
    }
}

function Read-SourceText([string]$RelPath) {
    $full = Join-Path $ScriptRoot $RelPath
    if (Test-Path $full) {
        return [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    }
    return ""
}

# ------------------------------------------------------------------------------
# FASE 1: LOGICA DE SELECCION Y RANKING (PACING ALGORITHM)
# ------------------------------------------------------------------------------
Write-Host "[1/5] Auditando algoritmo de seleccion publicitaria y pacing..." -ForegroundColor Yellow

$placementRepoSrc = Read-SourceText "src/ADSOLUSOL.Infrastructure/Repositories/PlacementRepository.cs"
$hasPacingSort = $placementRepoSrc -match 'ORDER\s+BY.*Budget.*BudgetSpent.*DESC'
Assert-Logic $hasPacingSort "LOGIC-PACING-SORT" "El ranking prioriza campanas ordenadas por mayor presupuesto remanente."

$hasActiveFilter = $placementRepoSrc -match "Status\s*=\s*'ACTIVE'"
Assert-Logic $hasActiveFilter "LOGIC-SERVE-ACTIVE" "Filtro autoritativo: solo campanas con Status ACTIVE pueden ser elegibles."

$hasDateGuards = $placementRepoSrc -match 'StartDateUtc\s*<=\s*@Now' -and $placementRepoSrc -match 'EndDateUtc\s*>=\s*@Now'
Assert-Logic $hasDateGuards "LOGIC-DATE-WINDOW" "Ventana de vigencia temporal UTC validada en la seleccion."

$hasSolvencyCheck = $placementRepoSrc -match '(?i)(Budget\s*>\s*BudgetSpent|Budget.*>.*BudgetSpent|BudgetSpent.*<.*Budget)'
Assert-Logic $hasSolvencyCheck "LOGIC-SOLVENCY-GUARD" "Filtro de solvencia: excluye campanas con saldo agotado."

# ------------------------------------------------------------------------------
# FASE 2: MAQUINA DE ESTADOS Y CONTROL DE TRANSICION
# ------------------------------------------------------------------------------
Write-Host "`n[2/5] Auditando maquina de estados de campana..." -ForegroundColor Yellow

$campSvcSrc = Read-SourceText "src/ADSOLUSOL.Application/Services/CampaignService.cs"
$hasStateMachine = $campSvcSrc -match 'isAllowedTransition\s*=\s*campaign\.Status\s*switch'
Assert-Logic $hasStateMachine "LOGIC-STATE-MACHINE" "CampaignService implementa evaluacion de transiciones permitidas mediante pattern matching."

$hasTerminalState = $campSvcSrc -match '"COMPLETED"\s*=>\s*false'
Assert-Logic $hasTerminalState "LOGIC-TERMINAL-COMPLETED" "El estado COMPLETED es modelado como estado terminal estricto (no reactivable)."

$normalizesStatus = $campSvcSrc -match 'targetStatus\s*=\s*status\.Trim\(\)\.ToUpperInvariant\(\)'
Assert-Logic $normalizesStatus "LOGIC-STATUS-NORM" "Normalizacion canonica de cadenas de estado a mayusculas."

# ------------------------------------------------------------------------------
# FASE 3: TARIFICACION Y CALCULOS UNITARIOS DE EVENTO
# ------------------------------------------------------------------------------
Write-Host "`n[3/5] Auditando logica de liquidacion de tarifas (CPM / CPC)..." -ForegroundColor Yellow

$eventProcSrc = Read-SourceText "src/ADSOLUSOL.Application/Services/EventProcessingService.cs"
$hasCpmMath = $eventProcSrc -match 'EventType\.Impression\s*=>\s*campaign\.CostPerMille\s*/\s*1000'
Assert-Logic $hasCpmMath "LOGIC-CPM-CALC" "Impresion liquidada como CostPerMille dividido entre mil exacto."

$hasCpcMath = $eventProcSrc -match 'EventType\.Click\s*=>\s*campaign\.CostPerClick'
Assert-Logic $hasCpcMath "LOGIC-CPC-CALC" "Clic liquidado como CostPerClick directo."

# ------------------------------------------------------------------------------
# FASE 4: LOGICA DE IDEMPOTENCIA Y PROTECCION CONTRA REPLAY
# ------------------------------------------------------------------------------
Write-Host "`n[4/5] Auditando compuertas de idempotencia y validacion temprana..." -ForegroundColor Yellow

$hasDedupFirst = $eventProcSrc -match 'ExistsAsync\s*\(\s*adEvent\.EventId\s*\)'
Assert-Logic $hasDedupFirst "LOGIC-IDEMPOTENCY-GATE" "Comprobacion previa de EventId previene mutaciones duplicadas."

$hasAssociationCheck = $eventProcSrc -match 'IsPlacementAssociatedAsync' -and $eventProcSrc -match 'IsCreativeAssociatedAsync'
Assert-Logic $hasAssociationCheck "LOGIC-RELATION-GUARD" "Rechazo automatico si placement o creativo no estan vinculados a la campana."

$hasStatusGuard = $eventProcSrc -match 'campaign\.Status\s*!=\s*"ACTIVE"'
Assert-Logic $hasStatusGuard "LOGIC-EVENT-STATUS-GUARD" "Eventos rechazados si la campana no esta en estado ACTIVE."

# ------------------------------------------------------------------------------
# FASE 5: INVARIANTES DE FORMULA DE METRICAS
# ------------------------------------------------------------------------------
Write-Host "`n[5/5] Auditando formulas de derivacion analitica..." -ForegroundColor Yellow

$metricsSrc = Read-SourceText "src/ADSOLUSOL.Application/Services/MetricsService.cs"
$hasCtrZeroDivGuard = $metricsSrc -match 'impressions\s*>\s*0' -and $metricsSrc -match '\*\s*100\.0'
Assert-Logic $hasCtrZeroDivGuard "LOGIC-CTR-FORMULA" "CTR protegido contra division por cero y expresado en base porcentual 100."

# ------------------------------------------------------------------------------
# DICTAMEN FINAL DE LOGICA
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN DE AUDITORIA DE LOGICA                      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Criticas : $logicaFails" -ForegroundColor $(if ($logicaFails -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias          : $logicaWarns" -ForegroundColor $(if ($logicaWarns -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($logicaFails -gt 0) {
    Write-Host "`n[FAIL] RECHAZADO: Infracciones logicas detectadas en el motor.`n" -ForegroundColor Red
    exit 1
} elseif ($logicaWarns -gt 0) {
    Write-Host "`n[PASS WITH WARNINGS] Observaciones logicas menores.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] Logica de decision, algoritmos de seleccion y maquina de estados impecables.`n" -ForegroundColor Green
    exit 0
}
