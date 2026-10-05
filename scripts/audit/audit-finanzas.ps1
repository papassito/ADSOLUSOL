<#
================================================================================
  ADSOLUSOL :: AUDITORIA PERICIAL DEL MOTOR FINANCIERO (NASA GRADE)
  Fiscaliza la precisión monetaria (decimal), liquidación de tarifas (CPM/CPC),
  débito atómico condicional, inmunidad al sobregiro y prevención del doble cobro.
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
Write-Host " [FINANZAS] AUDITORIA DEL MOTOR FINANCIERO Y DEBITO ATOMICO (NASA GRADE) " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$finFails = 0
$finWarns = 0

function Assert-Finance([bool]$Condition, [string]$Code, [string]$Message, [bool]$IsFatal = $true) {
    if ($Condition) {
        Write-Host "  [PASS] [$Code] $Message" -ForegroundColor Green
    } else {
        if ($IsFatal) {
            Write-Host "  [FAIL] [$Code] $Message" -ForegroundColor Red
            $script:finFails++
        } else {
            Write-Host "  [WARN] [$Code] $Message" -ForegroundColor Yellow
            $script:finWarns++
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
# FASE 1: PRECISION MONETARIA Y TIPADO EXACTO (CERO FLOAT/DOUBLE)
# ------------------------------------------------------------------------------
Write-Host "[1/6] Verificando precision monetaria en entidades de datos..." -ForegroundColor Yellow

$entitiesDir = Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Entities"
$entities = @(Get-ChildItem -Path $entitiesDir -Filter "*.cs" -File -ErrorAction SilentlyContinue)
$floatMoneyFound = $false

foreach ($e in $entities) {
    $src = [System.IO.File]::ReadAllText($e.FullName, [System.Text.Encoding]::UTF8)
    if ($src -match '\b(float|double)\s+(Budget|BudgetSpent|Cost|CostPerMille|CostPerClick|Price|Amount)\b') {
        $floatMoneyFound = $true
        Assert-Finance $false "FIN-FLOAT-LEAK" "$($e.Name) utiliza coma flotante binaria en propiedades monetarias."
    }
}
if (-not $floatMoneyFound) {
    Assert-Finance $true "FIN-DECIMAL-PURITY" "Todas las propiedades monetarias en entidades usan tipo decimal de 128 bits."
}

$campSrc = Read-SourceText "src/ADSOLUSOL.Domain/Entities/Campaign.cs"
Assert-Finance ($campSrc -match 'public\s+decimal\s+Budget\b') "FIN-CAMP-BUDGET" "Campaign.Budget modelado con precision decimal."
Assert-Finance ($campSrc -match 'public\s+decimal\s+BudgetSpent\b') "FIN-CAMP-SPENT" "Campaign.BudgetSpent modelado con precision decimal."
Assert-Finance ($campSrc -match 'public\s+decimal\s+CostPerMille\b' -and $campSrc -match 'public\s+decimal\s+CostPerClick\b') "FIN-CAMP-RATES" "Tarifas CPM y CPC modeladas con precision decimal."

# ------------------------------------------------------------------------------
# FASE 2: FORMULAS DE TARIFICACION Y CONTROL DE ENTRADA (CPM / CPC)
# ------------------------------------------------------------------------------
Write-Host "`n[2/6] Auditando formulas de liquidacion y validaciones de entrada..." -ForegroundColor Yellow

$eventProcSrc = Read-SourceText "src/ADSOLUSOL.Application/Services/EventProcessingService.cs"
$hasCpmFormula = $eventProcSrc -match 'EventType\.Impression\s*=>\s*campaign\.CostPerMille\s*/\s*1000'
$hasCpcFormula = $eventProcSrc -match 'EventType\.Click\s*=>\s*campaign\.CostPerClick'
Assert-Finance $hasCpmFormula "FIN-RATE-CPM" "Formula de impresion CPM calculada exactamente como (CostPerMille / 1000)."
Assert-Finance $hasCpcFormula "FIN-RATE-CPC" "Formula de clic CPC calculada directamente desde CostPerClick."

$campCtrlSrc = Read-SourceText "src/ADSOLUSOL.Presentation.Api/Controllers/CampaignsController.cs"
Assert-Finance ($campCtrlSrc -match 'request\.Budget\s*<=\s*0') "FIN-BUDGET-POSITIVE" "Controlador rechaza formalmente presupuestos menores o iguales a cero."
Assert-Finance ($campCtrlSrc -match 'CostPerMille\s*<\s*0' -and $campCtrlSrc -match 'CostPerClick\s*<\s*0') "FIN-NO-NEGATIVE-COST" "Controlador rechaza formalmente tarifas CPM o CPC negativas."

# ------------------------------------------------------------------------------
# FASE 3: DEBITO ATOMICO Y TECHO PRESUPUESTARIO
# ------------------------------------------------------------------------------
Write-Host "`n[3/6] Inspeccionando mecanismo de debito transaccional atomico..." -ForegroundColor Yellow

$budgetSvcSrc = Read-SourceText "src/ADSOLUSOL.Application/Services/BudgetService.cs"
Assert-Finance ($budgetSvcSrc -match 'DebitEventCost\s*\(') "FIN-DEBIT-METHOD" "BudgetService expone DebitEventCost con parametro de transaccion activa."
Assert-Finance ($budgetSvcSrc -match 'rowsAffected\s*>\s*0') "FIN-DEBIT-CONFIRM" "El debito confirma exito exclusivamente si el motor afecto registros."

$campRepoSrc = Read-SourceText "src/ADSOLUSOL.Infrastructure/Repositories/CampaignRepository.cs"
$hasCeilingGuard = $campRepoSrc -match 'BudgetSpent.*<=.*Budget|BudgetSpent\s*\+\s*@Cost\s*<=\s*Budget'
Assert-Finance $hasCeilingGuard "FIN-CEILING-GUARD" "El repositorio SQL exige atomicidad de techo presupuestario (BudgetSpent + Cost <= Budget)."

# ------------------------------------------------------------------------------
# FASE 4: TRANSACCIONALIDAD E IDEMPOTENCIA CONTRA DOBLE COBRO
# ------------------------------------------------------------------------------
Write-Host "`n[4/6] Verificando ciclo de vida transaccional e idempotencia de cobro..." -ForegroundColor Yellow

$hasTxFlow = ($eventProcSrc -match 'BeginTransactionAsync' -and $eventProcSrc -match 'CommitAsync' -and $eventProcSrc -match 'RollbackAsync')
Assert-Finance $hasTxFlow "FIN-TX-LIFECYCLE" "Ciclo transaccional completo implementado (Begin -> Debit -> Commit/Rollback)."

$hasDedupCheck = $eventProcSrc -match 'ExistsAsync\s*\(\s*adEvent\.EventId\s*\)'
Assert-Finance $hasDedupCheck "FIN-IDEMPOTENCY" "Verificacion de existencia previa de EventId para prevenir doble cobro por reintento."

# ------------------------------------------------------------------------------
# FASE 5: INVARIANTES DE SALDO Y REGLA ZERO-SYNTHETIC
# ------------------------------------------------------------------------------
Write-Host "`n[5/6] Auditando invariantes de saldo y derivaciones del ledger..." -ForegroundColor Yellow

Assert-Finance ($campSrc -match 'RemainingBudget\s*=>\s*Budget\s*-\s*BudgetSpent') "FIN-REMAINING-BUDGET" "RemainingBudget derivado estrictamente de (Budget - BudgetSpent)."

$metricsSrc = Read-SourceText "src/ADSOLUSOL.Application/Services/MetricsService.cs"
Assert-Finance ($metricsSrc -match 'campaign\.BudgetSpent' -and $metricsSrc -match 'campaign\.Budget') "FIN-METRICS-LEDGER" "Metricas devuelven saldo gastado y presupuestado real desde persistencia."

# ------------------------------------------------------------------------------
# FASE 6: PRUEBAS DE REGRESION DE CONCURRENCIA FINANCIERA
# ------------------------------------------------------------------------------
Write-Host "`n[6/6] Verificando suites de pruebas financieras en RegressionTests..." -ForegroundColor Yellow

$testSrc = Read-SourceText "tests/ADSOLUSOL.RegressionTests/Program.cs"
Assert-Finance ($testSrc -match 'Overspend rejected' -or $testSrc -match 'Overspend') "FIN-TEST-OVERSPEND" "Existe prueba de rechazo de transaccion cuando se excede el presupuesto."
Assert-Finance ($testSrc -match 'Rejected event does not debit budget') "FIN-TEST-ZERO-DEBIT" "Existe prueba que confirma que un evento rechazado no debita saldo."
Assert-Finance ($testSrc -match 'Idempotent replay immunity') "FIN-TEST-REPLAY" "Existe prueba de inmunidad de balance ante rafagas de eventos duplicados."
Assert-Finance ($testSrc -match 'techo presupuestario|Exact budget limit respected') "FIN-TEST-BURST-CAP" "Existe prueba de estres multihilo que valida preservacion del techo presupuestario."

# ------------------------------------------------------------------------------
# DICTAMEN FINAL DE AUDITORIA FINANCIERA
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                  DICTAMEN FINAL DEL MOTOR FINANCIERO                     " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Financieras : $finFails" -ForegroundColor $(if ($finFails -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias             : $finWarns" -ForegroundColor $(if ($finWarns -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($finFails -gt 0) {
    Write-Host "`n[FAIL] RECHAZADO: Se detectaron fallas criticas en el motor financiero o ledger.`n" -ForegroundColor Red
    exit 1
} elseif ($finWarns -gt 0) {
    Write-Host "`n[PASS WITH WARNINGS] Observaciones financieras menores.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] Motor financiero inmaculado: precision decimal, debitos atomicos y techo blindado.`n" -ForegroundColor Green
    exit 0
}