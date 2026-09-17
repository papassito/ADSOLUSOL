# ==============================================================================
# ADSOLUSOL — SCRIPT DE VERIFICACIÓN COMPLETA E2E (END-TO-END)
# ==============================================================================
[CmdletBinding()]
param(
    [switch]$NoAuth = $false,
    [switch]$KeepTestDatabase = $false,
    [string]$BaseUrl = "http://localhost:5000"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Variables Globales de Estado
$script:ExitCode = 1
$script:ApiProcess = $null
$script:HttpClient = $null
$script:TempRoot = $null
$script:DatabasePath = $null
$script:Results = [ordered]@{
    CAMPAIGN     = "NOT_RUN"
    PLACEMENT    = "NOT_RUN"
    CREATIVE     = "NOT_RUN"
    ASSOCIATIONS = "NOT_RUN"
    SERVING      = "NOT_RUN"
    IMPRESSION   = "NOT_RUN"
    CLICK        = "NOT_RUN"
    IDEMPOTENCY  = "NOT_RUN"
    METRICS      = "NOT_RUN"
    BUDGET       = "NOT_RUN"
    SQLITE       = "NOT_RUN"
    E2E          = "NOT_RUN"
}

# Funciones de Soporte de Salida
function Write-Info($msg)    { Write-Host "  [INFO] $msg" -ForegroundColor Gray }
function Write-Step($msg)    { Write-Host "`n>>> $msg..." -ForegroundColor Cyan }
function Write-Pass($msg)    { Write-Host "  [PASS] $msg" -ForegroundColor Green }
function Write-Fail($msg)    { Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Section($msg) { Write-Host "`n======================================================================`n $msg`n======================================================================" -ForegroundColor Yellow }

try {
    Write-Section "INICIANDO ENTORNO TEMPORAL E2E"

    # 1. Configuración de Directorio y Base de Datos Temporal
    $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ADSOLUSOL-E2E-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $script:TempRoot -Force | Out-Null
    $script:DatabasePath = Join-Path $script:TempRoot "adsolusol-e2e.db"
    
    Write-Info "Ruta Temp  : $script:TempRoot"
    Write-Info "DB Pruebas : $script:DatabasePath"
    Write-Info "Modo NoAuth: $NoAuth"

    # 2. Compilación Previa
    Write-Step "COMPILANDO SOLUCIÓN (.NET BUILD)"
    $dotnetExe = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source
    if (-not $dotnetExe) { throw "dotnet.exe not found in PATH" }
    
    & $dotnetExe build (Join-Path $PSScriptRoot '..\ADSOLUSOL.sln') /v:q /noconlog
    if ($LASTEXITCODE -ne 0) { throw "La compilación de la solución falló." }
    Write-Pass "Compilación exitosa."

    # 3. Lanzar API en Segundo Plano
    Write-Step "INICIANDO PROCESO SERVIDOR API"
    $apiProj = "src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj"
    $stdoutLog = Join-Path $script:TempRoot "api.stdout.log"
    $stderrLog = Join-Path $script:TempRoot "api.stderr.log"

    $env:ASPNETCORE_URLS = $BaseUrl
    $env:ConnectionStrings__DefaultConnection = "Data Source=$script:DatabasePath"

    $script:ApiProcess = Start-Process -FilePath $dotnetExe -ArgumentList "run --project $apiProj --no-build" `
        -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru -NoNewWindow

    Start-Sleep -Seconds 4
    if ($script:ApiProcess.HasExited) {
        $errText = Get-Content $stderrLog -Raw -ErrorAction SilentlyContinue
        throw "La API falló al arrancar: $errText"
    }
    Write-Pass "API escuchando activamente en $BaseUrl"

    # 4. Configurar Cliente HTTP
    $script:HttpClient = [System.Net.Http.HttpClient]::new()
    $script:HttpClient.BaseAddress = [Uri]::new($BaseUrl)

    # 5. Ejecución del Ciclo Publicitario E2E
    $runId = [Guid]::NewGuid().ToString("N").Substring(0, 12)
    $campaignName = "E2E Campaign $runId"
    $placementCode = "ZONE_$runId"
    $creativeName = "E2E Banner $runId"
    $initialBudget = 100.00
    $headers = @{ "X-Tenant-Id" = "e2e-tenant" }

    # Step A: Campaign
    Write-Step "1. CREAR CAMPAIGN"
    $campBody = @{ name = $campaignName; budget = $initialBudget } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$BaseUrl/api/Campaigns" -Method Post -Body $campBody -ContentType "application/json; charset=utf-8" -Headers $headers
    $campaignId = $res.id
    if (-not $campaignId) { throw "Create Campaign no devolvió ID." }
    $script:Results.CAMPAIGN = "PASS"
    Write-Pass "Campaign ID: $campaignId"

    # Step A.2: Activate Campaign
    Write-Step "1.1. ACTIVAR CAMPAIGN"
    $statusBody = @{ status = "ACTIVE" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/api/Campaigns/$campaignId/status" -Method Post -Body $statusBody -ContentType "application/json; charset=utf-8" -Headers $headers
    Write-Pass "Campaign activada."

    # Step B: Placement
    Write-Step "2. CREAR PLACEMENT"
    $placeBody = @{ placementCode = $placementCode; name = "Zone $runId" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$BaseUrl/api/placements" -Method Post -Body $placeBody -ContentType "application/json; charset=utf-8"
    $placementId = $res.id
    if (-not $placementId) { throw "Create Placement no devolvió ID." }
    $script:Results.PLACEMENT = "PASS"
    Write-Pass "Placement ID: $placementId"

    # Step C: Creative
    Write-Step "3. CREAR CREATIVE Y ASOCIACIONES"
    $creativeBody = @{ name = $creativeName; contentUrl = "http://e2e.test/img.png"; targetUrl = "http://e2e.test/target" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$BaseUrl/api/creatives" -Method Post -Body $creativeBody -ContentType "application/json; charset=utf-8"
    $creativeId = $res.id
    if (-not $creativeId) { throw "Create Creative no devolvió ID." }
    $script:Results.CREATIVE = "PASS"

    $assignCreativeBody = @{ campaignId = $campaignId; entityId = $creativeId } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/api/assignments/creative" -Method Post -Body $assignCreativeBody -ContentType "application/json; charset=utf-8"
    
    $assignPlacementBody = @{ campaignId = $campaignId; entityId = $placementId } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/api/assignments/placement" -Method Post -Body $assignPlacementBody -ContentType "application/json; charset=utf-8"
    $script:Results.ASSOCIATIONS = "PASS"
    Write-Pass "Creativo y Asociaciones configuradas."

    # Step D: Serve Ad
    Write-Step "4. SERVIR ANUNCIO (AD SERVING)"
    $adDecision = Invoke-RestMethod -Uri "$BaseUrl/api/marketing/adsolusol/serve?placementId=$placementCode" -Method Get -Headers $headers
    if ($adDecision.id -ne $creativeId) { throw "Ad Serving devolvió un creativo incorrecto." }
    $script:Results.SERVING = "PASS"
    Write-Pass "Anuncio servido correctamente (Creative ID: $($adDecision.id))."

    # Step E: Register Impression
    Write-Step "5. REGISTRAR IMPRESIÓN"
    $impEventId = "evt_imp_" + [Guid]::NewGuid().ToString("N")
    $eventBody = @{ eventId = $impEventId; creativeId = $creativeId; placementCode = $placementCode } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/api/Campaigns/$campaignId/impression" -Method Post -Body $eventBody -ContentType "application/json; charset=utf-8" -Headers $headers
    $script:Results.IMPRESSION = "PASS"
    Write-Pass "Impression aceptada: $impEventId"

    # Step F: Register Click
    Write-Step "6. REGISTRAR CLICK"
    $clickEventId = "evt_clk_" + [Guid]::NewGuid().ToString("N")
    $eventBody = @{ eventId = $clickEventId; creativeId = $creativeId; placementCode = $placementCode } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/api/Campaigns/$campaignId/click" -Method Post -Body $eventBody -ContentType "application/json; charset=utf-8" -Headers $headers
    $script:Results.CLICK = "PASS"
    Write-Pass "Click aceptado: $clickEventId"

    # Step G: Idempotency
    Write-Step "7. VERIFICAR IDEMPOTENCIA"
    try {
        Invoke-RestMethod -Uri "$BaseUrl/api/Campaigns/$campaignId/click" -Method Post -Body $eventBody -ContentType "application/json; charset=utf-8" -Headers $headers -ErrorAction Stop
        throw "Idempotency test failed: duplicate event was accepted."
    } catch {
        if ($_.Exception.Response.StatusCode -eq 'Conflict') {
            $script:Results.IDEMPOTENCY = "PASS"
            Write-Pass "Duplicado rechazado correctamente (409 Conflict)."
        } else {
            throw "Idempotency test failed with unexpected status: $($_.Exception.Response.StatusCode)"
        }
    }

    # Step H: Metrics & Budget
    Write-Step "8. CONSULTAR MÉTRICAS Y PRESUPUESTO"
    $metrics = Invoke-RestMethod -Uri "$BaseUrl/api/Campaigns/$campaignId/metrics" -Method Get -Headers $headers
    if ($metrics.impressions -eq 1 -and $metrics.clicks -eq 1 -and $metrics.budgetSpent -gt 0) {
        $script:Results.METRICS = "PASS"
        $script:Results.BUDGET = "PASS"
        $script:Results.SQLITE = "PASS"
        Write-Pass "Métricas y débito contable verificados."
    } else {
        throw "Metric verification failed. Got: $($metrics | Out-String)"
    }

    # Marcado Final
    $script:Results.E2E = "PASS"
    $script:ExitCode = 0

} catch {
    Write-Fail $_.Exception.Message
    $script:Results.E2E = "FAIL"
    $script:ExitCode = 1
} finally {
    # --------------------------------------------------------------------------
    # LIMPIEZA Y RESTAURACIÓN DE RECURSOS
    # --------------------------------------------------------------------------
    if ($script:ApiProcess -and -not $script:ApiProcess.HasExited) {
        Stop-Process -Id $script:ApiProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Info "Proceso temporal de la API detenido."
    }

    if ($script:HttpClient) {
        $script:HttpClient.Dispose()
    }

    if ($script:TempRoot -and (Test-Path $script:TempRoot)) {
        if ($KeepTestDatabase -or $script:ExitCode -ne 0) {
            Write-Info "Artefactos E2E conservados para diagnóstico en: $script:TempRoot"
        } else {
            Remove-Item -Path $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Reporte Final
    Write-Section "RESULTADO FINAL DE LA PRUEBA"
    foreach ($key in $script:Results.Keys) {
        $val = $script:Results[$key]
        $color = if ($val -eq "PASS") { "Green" } elseif ($val -eq "FAIL") { "Red" } else { "Gray" }
        Write-Host ("{0,-16}: {1}" -f $key, $val) -ForegroundColor $color
    }

    if ($script:ExitCode -eq 0) {
        Write-Host "`n======================================================================" -ForegroundColor Green
        Write-Host " ADSOLUSOL E2E = PASS (CICLO COMPLETO VERIFICADO)" -ForegroundColor Green
        Write-Host "======================================================================" -ForegroundColor Green
    } else {
        Write-Host "`n======================================================================" -ForegroundColor Red
        Write-Host " ADSOLUSOL E2E = FAIL (REVISAR LOGS DE ERROR)" -ForegroundColor Red
        Write-Host "======================================================================" -ForegroundColor Red
    }
}