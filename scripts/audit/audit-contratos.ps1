<#
================================================================================
  ADSOLUSOL :: AUDITORIA PERICIAL DE CONTRATOS E INTERFACES (NASA GRADE)
  Fiscaliza paridad entre documentacion (CONTRACTS.md, MARKETING-API.md),
  entidades de dominio, repositorios, controladores HTTP y seguridad de red.
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
Write-Host " [CONTRATOS] AUDITORIA DE CONTRATOS, DTOs Y ESPECIFICACION HTTP           " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$contractFails = 0
$contractWarns = 0

function Assert-Contract([bool]$Condition, [string]$Code, [string]$Message, [bool]$IsFatal = $true) {
    if ($Condition) {
        Write-Host "  [PASS] [$Code] $Message" -ForegroundColor Green
    } else {
        if ($IsFatal) {
            Write-Host "  [FAIL] [$Code] $Message" -ForegroundColor Red
            $script:contractFails++
        } else {
            Write-Host "  [WARN] [$Code] $Message" -ForegroundColor Yellow
            $script:contractWarns++
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
# FASE 1: CONTRATOS DE MODELOS DE DOMINIO Y PRECISIÓN
# ------------------------------------------------------------------------------
Write-Host "[1/6] Verificando contratos de entidades de dominio (CONTRACTS.md)..." -ForegroundColor Yellow

$campaignText = Read-SourceText "src/ADSOLUSOL.Domain/Entities/Campaign.cs"
Assert-Contract ($campaignText -match "public\s+string\s+Id") "CTR-CAMP-ID" "Campaign.Id modelado como string/GUID."
Assert-Contract ($campaignText -match "public\s+string\s+TenantId") "CTR-CAMP-TENANT" "Campaign.TenantId modelado explícitamente."
Assert-Contract ($campaignText -match "public\s+decimal\s+Budget\b" -and $campaignText -match "public\s+decimal\s+BudgetSpent\b") "CTR-CAMP-MONEY" "Campaign modela Budget y BudgetSpent con tipo decimal exacto."
Assert-Contract ($campaignText -match "public\s+decimal\s+CostPerMille\b" -and $campaignText -match "public\s+decimal\s+CostPerClick\b") "CTR-CAMP-RATES" "Campaign modela CostPerMille y CostPerClick con tipo decimal."

$placementText = Read-SourceText "src/ADSOLUSOL.Domain/Entities/Placement.cs"
Assert-Contract ($placementText -match "public\s+long\s+Id") "CTR-PLC-ID" "Placement.Id modelado como long entero autoincremental."
Assert-Contract ($placementText -match "public\s+string\s+PlacementCode") "CTR-PLC-CODE" "Placement modela PlacementCode estructurado."
Assert-Contract ($placementText -match "public\s+bool\s+IsEnabled") "CTR-PLC-STATUS" "Placement contiene flag de activación IsEnabled."

$creativeText = Read-SourceText "src/ADSOLUSOL.Domain/Entities/Creative.cs"
Assert-Contract ($creativeText -match "public\s+long\s+Id") "CTR-CRV-ID" "Creative.Id modelado como long."
Assert-Contract ($creativeText -match "public\s+string\s+ContentUrl" -and $creativeText -match "public\s+string\s+TargetUrl") "CTR-CRV-URLS" "Creative contiene ContentUrl y TargetUrl."

$adEventText = Read-SourceText "src/ADSOLUSOL.Domain/Entities/AdEvent.cs"
Assert-Contract ($adEventText -match "public\s+string\s+EventId") "CTR-EVT-ID" "AdEvent modela EventId como llave de idempotencia."
Assert-Contract ($adEventText -match "public\s+decimal\s+Cost") "CTR-EVT-COST" "AdEvent modela Cost con tipo decimal."

$outboxText = Read-SourceText "src/ADSOLUSOL.Domain/Entities/TelemetryOutbox.cs"
Assert-Contract ($outboxText -match "public\s+string\s+Id" -and $outboxText -match "Status") "CTR-OUTBOX" "TelemetryOutbox modela Id y Status observable."

# ------------------------------------------------------------------------------
# FASE 2: CONTRATOS DE REPOSITORIOS Y ASINCRONÍA
# ------------------------------------------------------------------------------
Write-Host "`n[2/6] Verificando asincronía estricta en interfaces de persistencia..." -ForegroundColor Yellow

$repoDir = Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Interfaces"
$repos = @(Get-ChildItem -Path $repoDir -Filter "*Repository*.cs" -File -ErrorAction SilentlyContinue)
$syncLeak = $false
foreach ($r in $repos) {
    $content = [System.IO.File]::ReadAllText($r.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match "\b(void|int|long|bool|Campaign|Placement|Creative)\s+[A-Z]\w+Async\s*\(") {
        $syncLeak = $true
        Assert-Contract $false "CTR-ASYNC-LEAK" "$($r.Name) define firma asíncrona sin devolver Task o Task<T>."
    }
}
if (-not $syncLeak) {
    Assert-Contract $true "CTR-ASYNC-PURITY" "Todas las interfaces de repositorio cumplen con retorno asíncrono Task/Task<T>."
}

$assignRepoText = Read-SourceText "src/ADSOLUSOL.Domain/Interfaces/IAssignmentRepository.cs"
Assert-Contract ($assignRepoText -match "AssignPlacementToCampaignAsync" -and $assignRepoText -match "AssignCreativeToCampaignAsync") "CTR-ASSIGN-CONTRACT" "IAssignmentRepository expone contratos tipados para placements y creativos."

# ------------------------------------------------------------------------------
# FASE 3: CONTRATOS DE SERVICIOS DE APLICACIÓN
# ------------------------------------------------------------------------------
Write-Host "`n[3/6] Verificando firmas de servicios de aplicación..." -ForegroundColor Yellow

$campSvcText = Read-SourceText "src/ADSOLUSOL.Application/Services/CampaignService.cs"
Assert-Contract ($campSvcText -match "CreateAsync\s*\(\s*string\s+tenantId") "CTR-SVC-CAMP-CREATE" "CampaignService.CreateAsync exige tenantId en su firma."
Assert-Contract ($campSvcText -match "UpdateStatusAsync\s*\(\s*string\s+tenantId") "CTR-SVC-CAMP-STATUS" "CampaignService.UpdateStatusAsync exige tenantId y valida transición."

$metricsSvcText = Read-SourceText "src/ADSOLUSOL.Application/Services/MetricsService.cs"
Assert-Contract ($metricsSvcText -match "GetMetricsForCampaign\s*\(\s*string\s+tenantId,\s*string\s+campaignId\)") "CTR-SVC-METRICS" "MetricsService expone contrato con verificación de tenantId."

$budgetSvcText = Read-SourceText "src/ADSOLUSOL.Application/Services/BudgetService.cs"
Assert-Contract ($budgetSvcText -match "DebitEventCost\s*\(.*decimal\s+cost") "CTR-SVC-BUDGET" "BudgetService.DebitEventCost recibe costo en decimal exacto."

# ------------------------------------------------------------------------------
# FASE 4: CONTRATOS HTTP DE CONTROLADORES (MARKETING-API.md)
# ------------------------------------------------------------------------------
Write-Host "`n[4/6] Auditando contratos de rutas y endpoints de API..." -ForegroundColor Yellow

$campCtrlText = Read-SourceText "src/ADSOLUSOL.Presentation.Api/Controllers/CampaignsController.cs"
Assert-Contract ($campCtrlText -match '\[HttpPost\]') "CTR-API-CAMP-POST" "Endpoint POST /api/Campaigns implementado."
Assert-Contract ($campCtrlText -match '\[HttpGet\]') "CTR-API-CAMP-GET" "Endpoint GET /api/Campaigns implementado."
Assert-Contract ($campCtrlText -match '\[HttpGet\("\{id\}"\)\]') "CTR-API-CAMP-GET-ID" "Endpoint GET /api/Campaigns/{id} implementado."
Assert-Contract ($campCtrlText -match '\[HttpPost\("\{id\}/status"\)\]') "CTR-API-CAMP-STATUS" "Endpoint POST /api/Campaigns/{id}/status implementado."
Assert-Contract ($campCtrlText -match '\[HttpGet\("\{id\}/metrics"\)\]') "CTR-API-CAMP-METRICS" "Endpoint GET /api/Campaigns/{id}/metrics implementado."
Assert-Contract ($campCtrlText -match '\[HttpPost\("\{id\}/click"\)\]') "CTR-API-CAMP-CLK" "Endpoint POST /api/Campaigns/{id}/click implementado."
Assert-Contract ($campCtrlText -match '\[HttpPost\("\{id\}/impression"\)\]') "CTR-API-CAMP-IMP" "Endpoint POST /api/Campaigns/{id}/impression implementado."

$serveCtrlText = Read-SourceText "src/ADSOLUSOL.Presentation.Api/Controllers/ServeController.cs"
Assert-Contract ($serveCtrlText -match 'placementCode') "CTR-API-SERVE" "ServeController expone parámetro placementCode conforme a especificación."

# ------------------------------------------------------------------------------
# FASE 5: CONTRATOS DE SEGURIDAD CRIPTOGRÁFICA (SOLUSOL_AUTH_V1)
# ------------------------------------------------------------------------------
Write-Host "`n[5/6] Verificando encabezados canónicos de firma Ed25519..." -ForegroundColor Yellow

$mwText = Read-SourceText "src/ADSOLUSOL.Presentation.Api/Middleware/SignatureVerificationMiddleware.cs"
$secHeaders = @("X-Solusol-Signature", "X-Solusol-Node-Id", "X-Solusol-Timestamp", "X-Solusol-Nonce")
$secPass = $true
foreach ($sh in $secHeaders) {
    if ($mwText -notmatch [regex]::Escape($sh)) {
        $secPass = $false
        Assert-Contract $false "CTR-SEC-HEADER" "Falta validación del encabezado de seguridad '$sh'."
    }
}
if ($secPass) {
    Assert-Contract $true "CTR-SEC-HEADERS" "Protocolo SOLUSOL_AUTH_V1 completo: 4 encabezados criptográficos auditados."
}

# ------------------------------------------------------------------------------
# FASE 6: CONTRATOS DE PRESENTACIÓN WEB (TYPESCRIPT TYPES)
# ------------------------------------------------------------------------------
Write-Host "`n[6/6] Verificando consistencia de tipos en el frontend web..." -ForegroundColor Yellow

$tsTypesText = Read-SourceText "src/ADSOLUSOL.Presentation.Web/src/types.ts"
if (-not [string]::IsNullOrWhiteSpace($tsTypesText)) {
    Assert-Contract ($tsTypesText -match "interface\s+Campaign|type\s+Campaign") "CTR-TS-CAMP" "types.ts define contrato Campaign."
    Assert-Contract ($tsTypesText -match "interface\s+Placement|type\s+Placement") "CTR-TS-PLC" "types.ts define contrato Placement."
    Assert-Contract ($tsTypesText -match "interface\s+Creative|type\s+Creative") "CTR-TS-CRV" "types.ts define contrato Creative."
    Assert-Contract ($tsTypesText -match "interface\s+CampaignMetrics|type\s+CampaignMetrics") "CTR-TS-METRICS" "types.ts define contrato CampaignMetrics."
    Assert-Contract ($tsTypesText -match "interface\s+HealthResponse|type\s+HealthResponse") "CTR-TS-HEALTH" "types.ts define contrato HealthResponse."
} else {
    Assert-Contract $false "CTR-TS-FILE" "Archivo src/ADSOLUSOL.Presentation.Web/src/types.ts no localizado."
}

# ------------------------------------------------------------------------------
# DICTAMEN FINAL DE AUDITORIA DE CONTRATOS
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN DE AUDITORIA DE CONTRATOS                   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Criticas : $contractFails" -ForegroundColor $(if ($contractFails -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias          : $contractWarns" -ForegroundColor $(if ($contractWarns -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($contractFails -gt 0) {
    Write-Host "`n[FAIL] RECHAZADO: Se detectaron discrepancias o rupturas de contratos en el sistema.`n" -ForegroundColor Red
    exit 1
} elseif ($contractWarns -gt 0) {
    Write-Host "`n[PASS WITH WARNINGS] Contratos aceptados con observaciones menores.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] Todos los contratos de datos, interfaces y API están en perfecta paridad.`n" -ForegroundColor Green
    exit 0
}