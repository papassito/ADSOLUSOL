<#
================================================================================
  ADSOLUSOL :: BENCHMARK & STRESS TEST
  Prueba de estrés concorrente HTTP contra el motor de Ad Serving
================================================================================
#>
[CmdletBinding()]
param(
    [string]$BaseUrl = "http://localhost:5000",
    [int]$TotalRequests = 500,
    [int]$Concurrency = 10,
    [switch]$AutoStart
)

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   ADSOLUSOL :: PRUEBA DE ESTRES Y RENDIMIENTO          " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Destino      : $BaseUrl" -ForegroundColor DarkGray
Write-Host "Peticiones   : $TotalRequests" -ForegroundColor DarkGray
Write-Host "Concurrencia : $Concurrency hilos simultaneos" -ForegroundColor DarkGray
Write-Host ""

$apiProcess = $null
$probeUrl = "$BaseUrl/api/v1/ads/serve?placementCode=P1"

# Función para comprobar si el puerto responde
function Test-ApiReady($url) {
    try {
        $r = Invoke-WebRequest -Uri $url -Method Get -Headers @{ "X-Solusol-Tenant" = "tenant-A" } -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        return $true
    } catch [System.Net.WebException] {
        return ($null -ne $_.Exception.Response)
    } catch {
        return $false
    }
}

if (-not (Test-ApiReady $probeUrl)) {
    if ($AutoStart) {
        Write-Host "[INFO] API no detectada en $BaseUrl. Iniciando automaticamente en segundo plano..." -ForegroundColor Yellow
        $apiProj = Join-Path $PSScriptRoot "src\ADSOLUSOL.Presentation.Api\ADSOLUSOL.Presentation.Api.csproj"
        $apiProcess = Start-Process -FilePath "dotnet" -ArgumentList "run --project `"$apiProj`" -c Release --no-build" -PassThru -WindowStyle Hidden
        
        for ($i = 0; $i -lt 15; $i++) {
            Start-Sleep -Milliseconds 800
            if (Test-ApiReady $probeUrl) { break }
        }
    }
}

try {
    $null = Invoke-WebRequest -Uri $probeUrl -Method Get -Headers @{ "X-Solusol-Tenant" = "tenant-A" } -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    Write-Host "[OK] Endpoint activo en $BaseUrl" -ForegroundColor Green
} catch [System.Net.WebException] {
    if ($_.Exception.Response) {
        Write-Host "[OK] Servidor detectado en $BaseUrl (Respondio HTTP $([int]$_.Exception.Response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] No se pudo conectar a $BaseUrl. Inicie la API o use: .\stress_test.ps1 -AutoStart" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[FAIL] Error conectando a $BaseUrl : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Compilador del runner multihilo nativo compatible con Windows PowerShell 5.1 y 7+
if (-not ([System.Management.Automation.PSTypeName]'AdSoluSol.Benchmarking.StressRunner').Type) {
    $csharpSource = @"
using System;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Concurrent;
using System.Text;

namespace AdSoluSol.Benchmarking
{
    public class BenchmarkResult
    {
        public int SuccessCount;
        public int FailCount;
        public double TotalSeconds;
        public string StatusBreakdown;
    }

    public static class StressRunner
    {
        public static BenchmarkResult Execute(string url, int totalRequests, int concurrency, int timeoutSec)
        {
            var result = new BenchmarkResult();
            var handler = new HttpClientHandler();
            using (var client = new HttpClient(handler))
            {
                client.Timeout = TimeSpan.FromSeconds(timeoutSec);
                var semaphore = new SemaphoreSlim(concurrency, concurrency);
                var statusMap = new ConcurrentDictionary<int, int>();
                var tasks = new Task[totalRequests];
                int success = 0;
                int failed = 0;

                var sw = System.Diagnostics.Stopwatch.StartNew();

                for (int i = 0; i < totalRequests; i++)
                {
                    tasks[i] = Task.Run(async () =>
                    {
                        await semaphore.WaitAsync();
                        try
                        {
                            using (var req = new HttpRequestMessage(HttpMethod.Get, url))
                            {
                                req.Headers.TryAddWithoutValidation("X-Solusol-Tenant", "tenant-A");
                                using (var resp = await client.SendAsync(req))
                                {
                                    int sc = (int)resp.StatusCode;
                                    statusMap.AddOrUpdate(sc, 1, (k, v) => v + 1);
                                    if (sc >= 200 && sc < 500) Interlocked.Increment(ref success);
                                    else Interlocked.Increment(ref failed);
                                }
                            }
                        }
                        catch { Interlocked.Increment(ref failed); }
                        finally { semaphore.Release(); }
                    });
                }

                Task.WaitAll(tasks);
                sw.Stop();
                result.SuccessCount = success;
                result.FailCount = failed;
                result.TotalSeconds = Math.Round(sw.Elapsed.TotalSeconds, 2);

                var sb = new StringBuilder();
                foreach (var kvp in statusMap) {
                    if (sb.Length > 0) sb.Append(", ");
                    sb.Append("HTTP ").Append(kvp.Key).Append(": ").Append(kvp.Value);
                }
                result.StatusBreakdown = sb.ToString();
                return result;
            }
        }
    }
}
"@
    Add-Type -TypeDefinition $csharpSource -ReferencedAssemblies "System.Net.Http"
}

Write-Host "`n>>> Iniciando rafaga de $TotalRequests peticiones concurrentes..." -ForegroundColor Yellow
$bench = [AdSoluSol.Benchmarking.StressRunner]::Execute($probeUrl, $TotalRequests, $Concurrency, 5)
$rps = [math]::Round($TotalRequests / [math]::Max($bench.TotalSeconds, 0.001), 2)

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "                RESULTADOS DEL BENCHMARK                 " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Tiempo total        : $($bench.TotalSeconds) s" -ForegroundColor White
Write-Host "Peticiones exitosas : $($bench.SuccessCount)" -ForegroundColor Green
Write-Host "Peticiones fallidas : $($bench.FailCount)" -ForegroundColor $(if ($bench.FailCount -eq 0) { "Green" } else { "Red" })
Write-Host "Rendimiento (RPS)   : $rps req/s" -ForegroundColor Cyan
Write-Host "Desglose respuestas : $($bench.StatusBreakdown)" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan

if ($apiProcess -and -not $apiProcess.HasExited) {
    Write-Host "`n[INFO] Deteniendo instancia temporal de la API (PID: $($apiProcess.Id))..." -ForegroundColor DarkGray
    Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
}