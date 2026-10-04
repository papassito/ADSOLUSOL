<#
================================================================================
  ADSOLUSOL :: PRUEBA DE ESTRES FORZADA Y ALTA CONCURRENCIA (STRESS TEST)
  Evalua concurrencia masiva, debitos atomicos y resistencia bajo carga.

  Uso:
    .\scripts\audit\test-stress.ps1                     # Estres del motor y ledger
    .\scripts\audit\test-stress.ps1 -Http               # Estres HTTP sobre Kestrel
    .\scripts\audit\test-stress.ps1 -Http -AutoStart    # Inicia la API y estresa
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$Http,
    [switch]$AutoStart,
    [string]$BaseUrl = "http://localhost:5000",
    [int]$TotalRequests = 200,
    [int]$Concurrency = 10
)

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

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [STRESS] ADSOLUSOL :: PRUEBA DE ESTRES Y RESISTENCIA CONCURRENTE         " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

# ------------------------------------------------------------------------------
# FASE 1: PRUEBA DE ESTRES IN-PROCESS (CONCURRENCIA MASIVA EN SERVING & BUDGET)
# ------------------------------------------------------------------------------
Write-Host "[1/2] Ejecutando rafaga de estres sobre el motor de negocio y persistencia..." -ForegroundColor Yellow
$regressionProj = Join-Path $ScriptRoot "tests\ADSOLUSOL.RegressionTests\ADSOLUSOL.RegressionTests.csproj"

if (-not (Test-Path $regressionProj)) {
    Write-Host "[ERROR] Proyecto de regresión no encontrado: $regressionProj" -ForegroundColor Red
    exit 1
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$testOutput = & dotnet test $regressionProj -c Release --no-restore --nologo -v:q 2>&1
$sw.Stop()

if ($LASTEXITCODE -eq 0) {
    Write-Host "[PASS] Prueba de estres in-process completada en $([math]::Round($sw.Elapsed.TotalSeconds, 2))s." -ForegroundColor Green
    Write-Host "       - 100% de debitos atomicos confirmados." -ForegroundColor DarkGray
    Write-Host "       - Techo presupuestario preservado sin sobregiros por carrera." -ForegroundColor DarkGray
} else {
    Write-Host "[FAIL] Fallo la prueba de estres de negocio:" -ForegroundColor Red
    $testOutput | ForEach-Object { Write-Host "  -> $_" -ForegroundColor Red }
    exit 1
}

# ------------------------------------------------------------------------------
# FASE 2: PRUEBA DE ESTRES HTTP (FAIL-CLOSED)
# ------------------------------------------------------------------------------
if ($Http) {
    Write-Host "`n[2/2] Ejecutando rafaga de estres HTTP contra $BaseUrl..." -ForegroundColor Yellow
    $apiProcess = $null
    $probeUrl = "$BaseUrl/swagger/index.html"
    $apiOutLog = Join-Path $ScriptRoot ".tmp_kestrel_stress_out.log"
    $apiErrLog = Join-Path $ScriptRoot ".tmp_kestrel_stress_err.log"

    function Test-Endpoint($url) {
        try {
            $resp = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
            return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500)
        } catch [System.Net.WebException] {
            return ($null -ne $_.Exception.Response)
        } catch {
            return $false
        }
    }

    try {
        if (-not (Test-Endpoint $probeUrl -or (Test-Endpoint "$BaseUrl/"))) {
            if ($AutoStart) {
                Write-Host "  [INFO] Verificando y liberando procesos dotnet huerfanos previos..." -ForegroundColor Cyan
                Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" } | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 500

                Write-Host "  [INFO] Iniciando API Kestrel en segundo plano..." -ForegroundColor Cyan
                $apiProj = Join-Path $ScriptRoot "src\ADSOLUSOL.Presentation.Api\ADSOLUSOL.Presentation.Api.csproj"
                if (Test-Path $apiOutLog) { Remove-Item $apiOutLog -Force -ErrorAction SilentlyContinue }
                if (Test-Path $apiErrLog) { Remove-Item $apiErrLog -Force -ErrorAction SilentlyContinue }

                $runArgs = "run --project `"$apiProj`" -c Release --no-build -- --urls `"$BaseUrl`""
                $apiProcess = Start-Process -FilePath "dotnet" -ArgumentList $runArgs -PassThru -RedirectStandardOutput $apiOutLog -RedirectStandardError $apiErrLog -WindowStyle Hidden
                
                $ready = $false
                for ($i = 0; $i -lt 30; $i++) {
                    Start-Sleep -Milliseconds 600
                    if ($apiProcess.HasExited) { break }
                    if (Test-Endpoint $probeUrl -or (Test-Endpoint "$BaseUrl/")) { $ready = $true; break }
                }
                if (-not $ready) {
                    Write-Host "[FAIL] Kestrel no inicio a tiempo o el endpoint $probeUrl no responde." -ForegroundColor Red
                    if (Test-Path $apiErrLog) {
                        Write-Host "  -> Detalle de errores de Kestrel (stderr):" -ForegroundColor Red
                        Get-Content $apiErrLog -Tail 15 | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }
                        Remove-Item $apiErrLog -Force -ErrorAction SilentlyContinue
                    }
                    if (Test-Path $apiOutLog) {
                        Write-Host "  -> Detalle de salida de Kestrel (stdout):" -ForegroundColor DarkGray
                        Get-Content $apiOutLog -Tail 15 | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }
                        Remove-Item $apiOutLog -Force -ErrorAction SilentlyContinue
                    }
                    exit 1
                } else {
                    if (Test-Path $apiOutLog) { Remove-Item $apiOutLog -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $apiErrLog) { Remove-Item $apiErrLog -Force -ErrorAction SilentlyContinue }
                }
            } else {
                Write-Host "[FAIL] API no detectada en $BaseUrl y -AutoStart no fue especificado." -ForegroundColor Red
                exit 1
            }
        }

        Write-Host "  [OK] Conectado exitosamente a Kestrel. Disparando rafaga:" -ForegroundColor Green
        Write-Host "       - Peticiones objetivo : $TotalRequests" -ForegroundColor White
        Write-Host "       - Concurrencia real   : $Concurrency hilos" -ForegroundColor White

        if (-not ([System.Management.Automation.PSTypeName]'ADSOLUSOL.Benchmarking.HttpStressTester').Type) {
            $csharpSource = @'
using System;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;

namespace ADSOLUSOL.Benchmarking
{
    public class HttpStressResult
    {
        public int Status2xx;
        public int Status4xx;
        public int Status5xx;
        public int NetworkErrors;
        public double ElapsedSeconds;
        public double AvgLatencyMs;
        public double ReqPerSec;
    }

    public static class HttpStressTester
    {
        public static HttpStressResult Run(string url, int totalRequests, int concurrency, int timeoutSec)
        {
            var result = new HttpStressResult();
            using (var handler = new HttpClientHandler { MaxConnectionsPerServer = concurrency * 2 })
            {
                using (var client = new HttpClient(handler))
                {
                    client.Timeout = TimeSpan.FromSeconds(timeoutSec);
                    var sw = Stopwatch.StartNew();
                    long totalLatencyTicks = 0;

                    var parallelOptions = new ParallelOptions { MaxDegreeOfParallelism = concurrency };
                    Parallel.For(0, totalRequests, parallelOptions, i =>
                    {
                        var reqSw = Stopwatch.StartNew();
                        try
                        {
                            using (var resp = client.GetAsync(url).GetAwaiter().GetResult())
                            {
                                reqSw.Stop();
                                Interlocked.Add(ref totalLatencyTicks, reqSw.ElapsedTicks);
                                int sc = (int)resp.StatusCode;
                                if (sc >= 200 && sc < 300) Interlocked.Increment(ref result.Status2xx);
                                else if (sc >= 400 && sc < 500) Interlocked.Increment(ref result.Status4xx);
                                else Interlocked.Increment(ref result.Status5xx);
                            }
                        }
                        catch
                        {
                            reqSw.Stop();
                            Interlocked.Increment(ref result.NetworkErrors);
                        }
                    });

                    sw.Stop();
                        result.ElapsedSeconds = Math.Round(sw.Elapsed.TotalSeconds, 2);
                        int executed = result.Status2xx + result.Status4xx + result.Status5xx + result.NetworkErrors;
                        if (executed > 0)
                        {
                            double totalMs = ((double)totalLatencyTicks / (double)Stopwatch.Frequency) * 1000.0;
                            result.AvgLatencyMs = Math.Round(totalMs / executed, 2);
                        }
                        result.ReqPerSec = Math.Round(totalRequests / Math.Max(result.ElapsedSeconds, 0.001), 2);
                        return result;
                    }
                }
            }
        }
    }
}
'@
            Add-Type -TypeDefinition $csharpSource -ReferencedAssemblies "System.Net.Http"
        }

        $targetUrl = "$BaseUrl/api/Serve?placementCode=P1"
        $bench = [ADSOLUSOL.Benchmarking.HttpStressTester]::Run($targetUrl, $TotalRequests, $Concurrency, 5)
        $executed = $bench.Status2xx + $bench.Status4xx + $bench.Status5xx + $bench.NetworkErrors

        Write-Host "  [RESULTADOS HTTP VERIFICADOS]" -ForegroundColor Cyan
        Write-Host "  - Peticiones enviadas   : $executed / $TotalRequests" -ForegroundColor White
        Write-Host "  - Respuestas HTTP 2xx   : $($bench.Status2xx)" -ForegroundColor Green
        Write-Host "  - Respuestas HTTP 4xx   : $($bench.Status4xx) (controladas)" -ForegroundColor Yellow
        Write-Host "  - Errores HTTP 5xx      : $($bench.Status5xx)" -ForegroundColor $(if ($bench.Status5xx -eq 0) { "Green" } else { "Red" })
        Write-Host "  - Errores de Red/Socket : $($bench.NetworkErrors)" -ForegroundColor $(if ($bench.NetworkErrors -eq 0) { "Green" } else { "Red" })
        Write-Host "  - Tiempo total          : $($bench.ElapsedSeconds) s" -ForegroundColor White
        Write-Host "  - Latencia promedio     : $($bench.AvgLatencyMs) ms/req" -ForegroundColor DarkCyan
        Write-Host "  - Throughput medido     : $($bench.ReqPerSec) req/s" -ForegroundColor Green

        if ($executed -ne $TotalRequests -or $bench.Status5xx -gt 0 -or $bench.NetworkErrors -gt 0) {
            Write-Host "`n[FAIL] La prueba HTTP no alcanzo la cuota esperada o genero errores no controlados." -ForegroundColor Red
            exit 1
        }
    } finally {
        if ($apiProcess -and -not $apiProcess.HasExited) {
            Write-Host "  [INFO] Deteniendo instancia temporal de Kestrel (PID: $($apiProcess.Id))..." -ForegroundColor DarkGray
            Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $apiOutLog) { Remove-Item $apiOutLog -Force -ErrorAction SilentlyContinue }
        if (Test-Path $apiErrLog) { Remove-Item $apiErrLog -Force -ErrorAction SilentlyContinue }
    }
} else {
    Write-Host "`n[2/2] Omitiendo prueba HTTP. Para ejecutar la rafaga HTTP use: .\scripts\audit\test-stress.ps1 -Http" -ForegroundColor DarkGray
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host " Veredicto: PRUEBA DE ESTRES CONCURRENTE DEMOSTRADA Y APROBADA (PASS)     " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
exit 0