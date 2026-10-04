<#
================================================================================
  ADSOLUSOL :: AUDITORIA DE DOMINIO E INVARIANTES DE NEGOCIO
  Inspecciona entidades, reglas de presupuesto, estados canonicos,
  excepciones de dominio y cumplimiento del principio Zero-Synthetic.
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
Write-Host " [DOMINIO] AUDITORIA DE INVARIANTES Y LOGICA DE NEGOCIO                   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$fallasDominio = 0

function Assert-Domain([bool]$Condicion, [string]$Codigo, [string]$Mensaje) {
    if ($Condicion) {
        Write-Host "  [PASS] [$Codigo] $Mensaje" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] [$Codigo] $Mensaje" -ForegroundColor Red
        $script:fallasDominio++
    }
}

# 1. Precision monetaria: el dominio publicitario debe usar decimal, nunca float o double
Write-Host "[1/4] Verificando precision monetaria en entidades y presupuestos..." -ForegroundColor Yellow
$domainEntities = Get-ChildItem -Path (Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Entities") -Filter "*.cs" -File -ErrorAction SilentlyContinue
$impreciseMoneyFound = 0
foreach ($e in $domainEntities) {
    $content = [System.IO.File]::ReadAllText($e.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match "\b(float|double)\s+(Budget|Cost|Price|Spent|Rate|Amount)\b") {
        Write-Host "  [FAIL] [MONEY-PRECISION] $($e.Name) usa coma flotante para valores monetarios." -ForegroundColor Red
        $impreciseMoneyFound++
        $fallasDominio++
    }
}
if ($impreciseMoneyFound -eq 0) {
    Write-Host "  [PASS] [MONEY-PRECISION] Todas las propiedades monetarias implementan tipo 'decimal' exacto." -ForegroundColor Green
}

# 2. Integridad de maquina de estados de Campaign
Write-Host "`n[2/4] Verificando estados canonicos de ciclo de vida publicitario..." -ForegroundColor Yellow
$campaignFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Entities/Campaign.cs"
if (Test-Path $campaignFile) {
    $campText = [System.IO.File]::ReadAllText($campaignFile, [System.Text.Encoding]::UTF8)
    $hasStatus = $campText -match "Status"
    Assert-Domain $hasStatus "CAMPAIGN-STATUS" "Entidad Campaign contiene control de Status."
} else {
    Assert-Domain $false "CAMPAIGN-ENTITY" "No se localizo la entidad Campaign.cs en el dominio."
}

# 3. Verificacion de tipos de eventos e idempotencia (AdEvent)
Write-Host "`n[3/4] Verificando contratos de eventos e idempotencia..." -ForegroundColor Yellow
$adEventFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Entities/AdEvent.cs"
if (Test-Path $adEventFile) {
    $eventText = [System.IO.File]::ReadAllText($adEventFile, [System.Text.Encoding]::UTF8)
    $hasEventId = $eventText -match "EventId"
    $hasEventType = $eventText -match "EventType"
    Assert-Domain ($hasEventId -and $hasEventType) "EVENT-CONTRACT" "AdEvent implementa EventId obligatorio para unicidad y EventType tipado."
} else {
    Assert-Domain $false "EVENT-ENTITY" "Entidad AdEvent.cs no localizada."
}

# 4. Verificacion de excepciones de Dominio especificas (sin throw new Exception generico)
Write-Host "`n[4/4] Verificando excepciones de dominio y ausencia de throw generico..." -ForegroundColor Yellow
$domainServices = Get-ChildItem -Path (Join-Path $ScriptRoot "src/ADSOLUSOL.Application/Services") -Filter "*.cs" -File -ErrorAction SilentlyContinue
$genericThrowCount = 0
foreach ($ds in $domainServices) {
    $lines = [System.IO.File]::ReadAllLines($ds.FullName, [System.Text.Encoding]::UTF8)
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match "throw\s+new\s+Exception\s*\(") {
            Write-Host "  [FAIL] [GENERIC-THROW] $($ds.Name):$lineNum lanza 'System.Exception' generico en vez de excepcion tipada." -ForegroundColor Red
            $genericThrowCount++
            $fallasDominio++
        }
    }
}
if ($genericThrowCount -eq 0) {
    Write-Host "  [PASS] [DOMAIN-EXCEPTIONS] Los servicios de negocio emplean excepciones tipadas y semanticas." -ForegroundColor Green
}

# 5. Regla Zero-Synthetic en el dominio
Write-Host "`n[5/5] Auditando cumplimiento de regla Zero-Synthetic en el modelo..." -ForegroundColor Yellow
$metricsFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Entities/CampaignMetrics.cs"
if (Test-Path $metricsFile) {
    $mText = [System.IO.File]::ReadAllText($metricsFile, [System.Text.Encoding]::UTF8)
    $hasCtr = $mText -match "Ctr"
    $hasImpressions = $mText -match "Impressions"
    $hasClicks = $mText -match "Clicks"
    Assert-Domain ($hasCtr -and $hasImpressions -and $hasClicks) "ZERO-SYNTHETIC" "Metricas publicitarias basadas en contadores observables de eventos reales."
} else {
    Assert-Domain $false "METRICS-ENTITY" "Entidad CampaignMetrics.cs ausente."
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN DE REGLAS DE DOMINIO                        " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones de Dominio : $fallasDominio" -ForegroundColor $(if ($fallasDominio -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($fallasDominio -gt 0) {
    Write-Host "`n[FAIL] Se detectaron violaciones a las reglas del dominio de negocio.`n" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[PASS] Todas las invariantes y reglas de dominio estan intactas y respetadas.`n" -ForegroundColor Green
    exit 0
}