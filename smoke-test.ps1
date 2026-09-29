[CmdletBinding()]
param(
    [string]$BaseUrl = "http://localhost:5000",
    [switch]$Stress,
    [int]$BurstCount = 50,
    [int]$Concurrency = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Garantizar ensamblado HTTP para Windows PowerShell 5.1 y Core
try {
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
} catch {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Net.Http") | Out-Null
}

# --- Configuration ---
$cleanBase = $BaseUrl.Trim('<', '>', ' ', '"', "'").TrimEnd('/')
$livenessUrl = "$cleanBase/health"
$healthUrl = "$cleanBase/api/health"
$swaggerUrl = "$cleanBase/swagger/index.html"

# --- Funciones de Ayuda ---
function Test-Endpoint {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host "[*] Ejecutando prueba: $Name..." -ForegroundColor Yellow
    try {
        $result = & $Action
        Write-Host "   [PASS] $Name" -ForegroundColor Green
        return $result
    } catch {
        Write-Host "   [FAIL] $Name" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.PSObject.Properties.Match('Response').Count -gt 0 -and $null -ne $_.Exception.Response) {
            $responseBody = $_.Exception.Response.GetResponseStream()
            if ($null -ne $responseBody) {
                $reader = New-Object System.IO.StreamReader($responseBody)
                $body = $reader.ReadToEnd()
                Write-Host "   Response Body: $body" -ForegroundColor Red
            }
        }
        # Terminar el script si una prueba crítica falla
        exit 1
    }
}

Write-Host "===========================================================" -f Cyan
Write-Host " SMOKE TEST - VERIFICACIÓN DE ENDPOINTS EN EJECUCIÓN" -f Cyan
Write-Host "===========================================================" -f Cyan
Write-Host "Destino Base : $cleanBase" -f DarkGray
Write-Host "Fecha/Hora   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor DarkGray

# 1. Probar /health (Liveness básico de Kestrel)
$livenessResult = Test-Endpoint -Name "/health" -Action {
    Invoke-RestMethod -Uri $livenessUrl -Method Get -TimeoutSec 10
}

# 2. Probar /api/health (Integración profunda SQLite + SIC)
$healthResult = Test-Endpoint -Name "/api/health" -Action {
    Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 10
}

if ($null -ne $healthResult) {
    $hasChecks = [bool]($healthResult.PSObject.Properties.Match('checks').Count -gt 0 -and $null -ne $healthResult.checks)
    $dbStatus  = if ($hasChecks -and $healthResult.checks.PSObject.Properties.Match('database').Count -gt 0) { $healthResult.checks.database } else { "N/A" }
    $sicStatus = if ($hasChecks -and $healthResult.checks.PSObject.Properties.Match('sicEngine').Count -gt 0) { $healthResult.checks.sicEngine } else { "N/A" }
    Write-Host "   -> Estado subsistemas: Database=$dbStatus, SicEngine=$sicStatus" -ForegroundColor DarkCyan
}

# 3. Probar documentación interactiva Swagger
Test-Endpoint -Name "/swagger" -Action {
    $res = Invoke-WebRequest -Uri $swaggerUrl -Method Get -TimeoutSec 10 -UseBasicParsing
    if ($res.StatusCode -ne 200) { throw "Código inesperado HTTP $($res.StatusCode)" }
}

# 4. Stress Test Concurrente (Opcional con -Stress)
if ($Stress) {
    Write-Host "`n[*] Iniciando Stress Test de Rendimiento HTTP..." -ForegroundColor Yellow
    Write-Host "    -> Peticiones totales : $BurstCount" -ForegroundColor DarkGray
    Write-Host "    -> Concurrencia       : $Concurrency hilos" -ForegroundColor DarkGray
    Write-Host "    -> Endpoint evaluado  : $livenessUrl" -ForegroundColor DarkGray

    [System.Net.ServicePointManager]::DefaultConnectionLimit = [Math]::Max(50, $Concurrency * 2)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

    $httpClient = New-Object System.Net.Http.HttpClient
    $httpClient.Timeout = [TimeSpan]::FromSeconds(10)
    $latencies = [System.Collections.Concurrent.ConcurrentBag[double]]::new()
    $errorCount = 0
    $throttle = [System.Threading.SemaphoreSlim]::new($Concurrency, $Concurrency)

    $swTotal = [System.Diagnostics.Stopwatch]::StartNew()

    $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()

    for ($i = 0; $i -lt $BurstCount; $i++) {
        $task = [System.Threading.Tasks.Task]::Run([Action]{
            $throttle.Wait()
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $res = $httpClient.GetAsync($livenessUrl).GetAwaiter().GetResult()
                $sw.Stop()
                if ($res.IsSuccessStatusCode) {
                    $latencies.Add($sw.Elapsed.TotalMilliseconds)
                } else {
                    [System.Threading.Interlocked]::Increment([ref]$errorCount) | Out-Null
                }
            } catch {
                $sw.Stop()
                [System.Threading.Interlocked]::Increment([ref]$errorCount) | Out-Null
            } finally {
                $throttle.Release() | Out-Null
            }
        })
        $tasks.Add($task)
    }

        try {
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
    } finally {
        $httpClient.Dispose()
        $throttle.Dispose()
    }

    $swTotal.Stop()
    $latenciesList = @($latencies)
    $totalSec = [math]::Max($swTotal.Elapsed.TotalSeconds, 0.001)
    $totalReqs = $latenciesList.Count
    $avgMs = if ($totalReqs -gt 0) { [math]::Round(($latenciesList | Measure-Object -Average).Average, 2) } else { 0 }
    $rps = [math]::Round($totalReqs / $totalSec, 2)

    Write-Host "   [STRESS RESULTS]" -ForegroundColor Cyan
    $statusColor = if ($totalReqs -eq $BurstCount -and $errorCount -eq 0) { "Green" } else { "Red" }
    Write-Host "   Completadas : $totalReqs / $BurstCount (Errores: $errorCount)" -ForegroundColor $statusColor
    Write-Host "   Latencia Promedio : ${avgMs} ms" -ForegroundColor Green
    Write-Host "   Throughput : $rps req/s (en ${totalSec}s)" -ForegroundColor Green

    if ($errorCount -gt 0 -or $totalReqs -lt $BurstCount) {
        Write-Host "   [FAIL] El Stress Test registro anomalias o solicitudes no completadas." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n===========================================================" -f Cyan
Write-Host " [PASS] SMOKE TEST DE PRODUCCION COMPLETADO CON EXITO" -f Green
Write-Host "===========================================================" -f Cyan