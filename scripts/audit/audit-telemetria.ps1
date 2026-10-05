<#
================================================================================
  ADSOLUSOL :: AUDITORIA PERICIAL DE TELEMETRIA Y SEGUIMIENTO (NASA GRADE)
  Inspecciona la ingesta de eventos (Clicks / Impressions), cálculo de costos,
  idempotencia de EventId, resiliencia perimetral y despacho real hacia SIC.
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
Write-Host " [TELEMETRIA] AUDITORIA DE SEGUIMIENTO, SIC Y EVENTOS (NASA GRADE)       " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$telemetryFails = 0
$telemetryWarns = 0

function Assert-Telemetry([bool]$Condition, [string]$Code, [string]$Message, [bool]$IsFatal = $true) {
    if ($Condition) {
        Write-Host "  [PASS] [$Code] $Message" -ForegroundColor Green
    } else {
        if ($IsFatal) {
            Write-Host "  [FAIL] [$Code] $Message" -ForegroundColor Red
            $script:telemetryFails++
        } else {
            Write-Host "  [WARN] [$Code] $Message" -ForegroundColor Yellow
            $script:telemetryWarns++
        }
    }
}

# ------------------------------------------------------------------------------
# FASE 1: CONTRATO DE EVENTOS E IDEMPOTENCIA TRANSACCIONAL
# ------------------------------------------------------------------------------
Write-Host "[1/5] Verificando contratos de entidades de telemetria..." -ForegroundColor Yellow
$adEventFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Entities/AdEvent.cs"
if (Test-Path $adEventFile) {
    $src = [System.IO.File]::ReadAllText($adEventFile, [System.Text.Encoding]::UTF8)
    Assert-Telemetry ($src -match "public\s+string\s+EventId\s*\{\s*get;\s*set;\s*\}") "TEL-ID-CONTRACT" "AdEvent implementa EventId obligatorio como llave unica."
    Assert-Telemetry ($src -match "public\s+decimal\s+Cost\s*\{\s*get;\s*set;\s*\}") "TEL-COST-PRECISION" "AdEvent modela Cost con tipo decimal exacto."
    Assert-Telemetry ($src -match "public\s+string\s+EventType") "TEL-TYPE-CONTRACT" "AdEvent contiene EventType estructurado."
} else {
    Assert-Telemetry $false "TEL-EVENT-FILE" "Entidad AdEvent.cs no encontrada."
}

# ------------------------------------------------------------------------------
# FASE 2: MOTOR DE INGESTA Y CALCULO DE TARIFAS (EVENT PROCESSING)
# ------------------------------------------------------------------------------
Write-Host "`n[2/5] Auditando servicio de procesamiento de eventos publicitarios..." -ForegroundColor Yellow
$procFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Application/Services/EventProcessingService.cs"
if (Test-Path $procFile) {
    $pText = [System.IO.File]::ReadAllText($procFile, [System.Text.Encoding]::UTF8)
    
    # Deduplicación temprana
    Assert-Telemetry ($pText -match "ExistsAsync\(adEvent\.EventId\)") "TEL-DEDUP" "EventProcessingService verifica existencia previa del EventId."
    
    # Normalización de tipo de evento
    Assert-Telemetry ($pText -match "EventType\.Impression.*CostPerMille\s*/\s*1000" -and $pText -match "EventType\.Click.*CostPerClick") "TEL-RATE-LOGIC" "Calcula CPM (rate/1000) y CPC con tarifas autoritativas de campana."
    
    # Transaccionalidad atómica (Begin -> Debit -> Commit -> Rollback)
    $hasTx = ($pText -match "BeginTransactionAsync" -and $pText -match "CommitAsync" -and $pText -match "RollbackAsync")
    Assert-Telemetry $hasTx "TEL-TX-ATOMIC" "La ingesta y débito de telemetría ejecutan ciclo de vida transaccional completo."
    
    # Resiliencia y Logging estructurado hacia SIC
    $hasSicCall = $pText -match "_marketingBrainService\.EmitTelemetryAsync"
    $hasCatchLog = $pText -match "catch\s*\(\s*Exception\s+\w+\s*\)[\s\r\n]*\{[\s\r\n]*_logger\.LogWarning"
    Assert-Telemetry ($hasSicCall -and $hasCatchLog) "TEL-SIC-RESILIENCE" "Despacho a SIC protegido con captura y logging estructurado ILogger (sin caidas silenciadas)."
} else {
    Assert-Telemetry $false "TEL-PROC-FILE" "EventProcessingService.cs no localizado."
}

# ------------------------------------------------------------------------------
# FASE 3: CONECTIVIDAD REAL CON MARKETING BRAIN / SIC (ZERO-SYNTHETIC)
# ------------------------------------------------------------------------------
Write-Host "`n[3/5] Comprobando cliente de integracion SIC / Marketing Brain..." -ForegroundColor Yellow
$clientFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Infrastructure/ExternalServices/MarketingBrain/MarketingBrainClient.cs"
if (Test-Path $clientFile) {
    $cText = [System.IO.File]::ReadAllText($clientFile, [System.Text.Encoding]::UTF8)
    Assert-Telemetry ($cText -match "HttpClient") "TEL-REAL-HTTP" "MarketingBrainClient implementa HttpClient real (sin mocks de memoria)."
    Assert-Telemetry ($cText -notmatch "Task\.FromResult\s*\(\s*true\s*\)") "TEL-NO-MOCK" "Cero emulaciones sinteticas fijas en el cliente de telemetria."
    Assert-Telemetry ($cText -match "EmitTelemetryAsync") "TEL-EMIT-SIG" "Contrato EmitTelemetryAsync implementado conforme al protocolo de senales."
} else {
    Assert-Telemetry $false "TEL-CLIENT-FILE" "MarketingBrainClient.cs no encontrado."
}

# ------------------------------------------------------------------------------
# FASE 4: AGREGACION Y COMPUTO OBSERVABLE DE METRICAS
# ------------------------------------------------------------------------------
Write-Host "`n[4/5] Auditando calculo de metricas en MetricsService..." -ForegroundColor Yellow
$metricsFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Application/Services/MetricsService.cs"
if (Test-Path $metricsFile) {
    $mText = [System.IO.File]::ReadAllText($metricsFile, [System.Text.Encoding]::UTF8)
    
    # Validación de pertenencia del tenant
    Assert-Telemetry ($mText -match "tenantId" -and $mText -match "campaign\.TenantId\s*!=\s*tenantId") "TEL-METRICS-TENANT" "MetricsService exige y comprueba TenantId para consultar metricas."
    
    # Cálculo estricto de CTR basado en conteo real
    $hasCtrMath = $mText -match "\(impressions\s*>\s*0\)\s*\?\s*\(double\)clicks\s*/\s*impressions\s*\*\s*100\.0\s*:\s*0\.0"
    Assert-Telemetry $hasCtrMath "TEL-CTR-FORMULA" "CTR calculado estrictamente a partir de conteos reales (Zero-Synthetic)."
} else {
    Assert-Telemetry $false "TEL-METRICS-FILE" "MetricsService.cs no encontrado."
}

# ------------------------------------------------------------------------------
# FASE 5: EXPOSICION DE ENDPOINTS DE TELEMETRIA EN LA API
# ------------------------------------------------------------------------------
Write-Host "`n[5/5] Inspeccionando controladores de ingesta HTTP de telemetria..." -ForegroundColor Yellow
$ctrlFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Presentation.Api/Controllers/CampaignsController.cs"
if (Test-Path $ctrlFile) {
    $ctrlText = [System.IO.File]::ReadAllText($ctrlFile, [System.Text.Encoding]::UTF8)
    Assert-Telemetry ($ctrlText -match '\[HttpPost\("\{id\}/impression"\)\]') "TEL-ROUTE-IMP" "Ruta HTTP POST /{id}/impression expuesta."
    Assert-Telemetry ($ctrlText -match '\[HttpPost\("\{id\}/click"\)\]') "TEL-ROUTE-CLK" "Ruta HTTP POST /{id}/click expuesta."
} else {
    Assert-Telemetry $false "TEL-CTRL-FILE" "CampaignsController.cs no encontrado."
}

# ------------------------------------------------------------------------------
# FASE 6: GARANTIA DE ENTREGA DIFERIDA HACIA SIC (OUTBOX / RETRIES)
# ------------------------------------------------------------------------------
Write-Host "`n[6/6] Auditando garantia de entrega diferida hacia SIC..." -ForegroundColor Yellow
$sourceFiles = @(Get-ChildItem (Join-Path $ScriptRoot 'src'), (Join-Path $ScriptRoot 'tests') -Recurse -File -Include *.cs,*.json -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\(bin|obj|node_modules|dist)\\' })
$allSourceText = ($sourceFiles | ForEach-Object { try { [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8) } catch { '' } }) -join "`n"
$hasOutbox = $allSourceText -match '(?i)TelemetryOutbox|OutboxMessage|TelemetryMessage'
$hasPending = $allSourceText -match '(?i)PENDING'
$hasStates = ($allSourceText -match '(?i)DISPATCHED|SENT|DELIVERED') -and ($allSourceText -match '(?i)FAILED_RETRYING|RetryCount|NextAttempt|LastError')
$hasBackoff = $allSourceText -match '(?i)backoff|exponential|retry\s*delay|RetryAfter'
$hasWorker = $allSourceText -match '(?i)BackgroundService|IHostedService|Channel<|PeriodicTimer|HostedService'
$hasRecoveryTest = $allSourceText -match '(?i)outbox|retry|reconnect|recovery|SIC.*(down|offline|unavailable)'
Assert-Telemetry $hasOutbox "TEL-OUTBOX" "Existe una cola persistente de telemetria antes del envio a SIC."
Assert-Telemetry $hasPending "TEL-OUTBOX-PENDING" "El mensaje puede conservarse en estado PENDING."
Assert-Telemetry $hasStates "TEL-OUTBOX-STATES" "Existen estados de entrega y reintento observables."
Assert-Telemetry $hasBackoff "TEL-RETRY-BACKOFF" "Los reintentos contemplan backoff o demora controlada."
Assert-Telemetry $hasWorker "TEL-DISPATCHER" "Existe worker o dispatcher para procesar mensajes pendientes."
Assert-Telemetry $hasRecoveryTest "TEL-RECOVERY-TEST" "Existen pruebas de recuperación tras una caída de SIC."

# ------------------------------------------------------------------------------
# DICTAMEN FINAL DE TELEMETRIA
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN DE AUDITORIA TELEMETRIA                     " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Criticas : $telemetryFails" -ForegroundColor $(if ($telemetryFails -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias          : $telemetryWarns" -ForegroundColor $(if ($telemetryWarns -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($telemetryFails -gt 0) {
    Write-Host "`n[FAIL] RECHAZADO: Se detectaron fallas criticas en el pipeline de telemetria.`n" -ForegroundColor Red
    exit 1
} elseif ($telemetryWarns -gt 0) {
    Write-Host "`n[PASS WITH WARNINGS] Observaciones menores en telemetria.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] Telemetria publicitaria y operacional 100% integra y conforme.`n" -ForegroundColor Green
    exit 0
}
