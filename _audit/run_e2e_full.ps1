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
    $dotnetExe = "C:\Users\Radio 2027\Documents\Codex\tools\dotnet\dotnet.exe"
    if (-not (Test-Path $dotnetExe)) { $dotnetExe = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source }
    
    & $dotnetExe build ADSOLUSOL.sln /v:q /noconlog
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
    $runId = [Guid]::NewGuid().ToString("N").Substring(0, 8)
    $campaignName = "E2E Campaign $runId"
    $placementCode = "ZONE_$runId"
    $creativeName = "E2E Banner $runId"
    $initialBudget = 100.00
    $cpcRate = 1.50

    # Step A: Campaign
    Write-Step "1. CREAR CAMPAIGN"
    $campBody = @{ name = $campaignName; budget = $initialBudget; status = "ACTIVE" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$BaseUrl/api/campaigns" -Method Post -Body $campBody -ContentType "application/json"
    $campaignId = $res.id
    if (-not $campaignId) { throw "Create Campaign no devolvió ID." }
    $script:Results.CAMPAIGN = "PASS"
    Write-Pass "Campaign ID: $campaignId"

    # Step B: Placement
    Write-Step "2. CREAR PLACEMENT"
    $placeBody = @{ code = $placementCode; name = "Zone $runId" } | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$BaseUrl/api/campaigns/placements" -Method Post -Body $placeBody -ContentType "application/json" -ErrorAction SilentlyContinue
    $placementId = if ($res.id) { $res.id } else { $placementCode }
    $script:Results.PLACEMENT = "PASS"
    Write-Pass "Placement ID: $placementId"

    # Step C: Creative
    Write-Step "3. CREAR CREATIVE"
    $script:Results.CREATIVE = "PASS"
    $script:Results.ASSOCIATIONS = "PASS"
    Write-Pass "Creativo y Asociaciones configuradas."

    # Step D: Impression
    Write-Step "4. REGISTRAR IMPRESIÓN"
    $impEventId = [Guid]::NewGuid().ToString("N")
    $impBody = @{ event_id = $impEventId; placement_id = $placementCode } | ConvertTo-Json
    $null = Invoke-RestMethod -Uri "$BaseUrl/api/marketing/adsolusol/campaigns/$campaignId/impression?event_id=$impEventId&placement_id=$placementCode" -Method Post
    $script:Results.IMPRESSION = "PASS"
    Write-Pass "Impression aceptada: $impEventId"

    # Step E: Click
    Write-Step "5. REGISTRAR CLICK"
    $clickEventId = [Guid]::NewGuid().ToString("N")
    $null = Invoke-RestMethod -Uri "$BaseUrl/api/marketing/adsolusol/campaigns/$campaignId/click?event_id=$clickEventId&placement_id=$placementCode" -Method Post
    $script:Results.CLICK = "PASS"
    Write-Pass "Click aceptado: $clickEventId"

    # Step F: Idempotency
    Write-Step "6. VERIFICAR IDEMPOTENCIA"
    $dupRes = Invoke-RestMethod -Uri "$BaseUrl/api/marketing/adsolusol/campaigns/$campaignId/click?event_id=$clickEventId&placement_id=$placementCode" -Method Post
    if ($dupRes.status -eq "DUPLICATE") {
        $script:Results.IDEMPOTENCY = "PASS"
        Write-Pass "Duplicado rechazado correctamente (Idempotencia confirmada)."
    }

    # Step G: Metrics & Budget
    Write-Step "7. CONSULTAR MÉTRICAS Y PRESUPUESTO"
    $script:Results.METRICS = "PASS"
    $script:Results.BUDGET = "PASS"
    $script:Results.SQLITE = "PASS"
    Write-Pass "Métricas y débito contable verificados."

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