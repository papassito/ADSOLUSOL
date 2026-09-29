[CmdletBinding()]
param(
    [string]$BaseUrl = "http://localhost:5000"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- Configuration ---
$cleanBase = $BaseUrl.TrimEnd('/')
$livenessUrl = "$cleanBase/health"
$baseApiUrl = "$cleanBase/api"
$healthUrl = "$cleanBase/api/health"
$swaggerUrl = "$cleanBase/swagger"

# Test identity corresponding to the mock NodeRegistry
$nodeId = "NODE_ADS_01"

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
        if ($_.Exception.Response) {
            $responseBody = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($responseBody)
            $reader.BaseStream.Position = 0
            $body = $reader.ReadToEnd()
            Write-Host "   Response Body: $body" -ForegroundColor Red
        }
        # Terminar el script si una prueba crítica falla
        exit 1
    }
}

Write-Host "===========================================================" -f Cyan
Write-Host " SMOKE TEST - VERIFICACIÓN DE ENDPOINTS EN EJECUCIÓN" -f Cyan
Write-Host "===========================================================" -f Cyan
Write-Host "Destino Base : $cleanBase" -ForegroundColor DarkGray
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
    $dbStatus  = if ($healthResult.checks) { $healthResult.checks.database } else { "N/A" }
    $sicStatus = if ($healthResult.checks) { $healthResult.checks.sicEngine } else { "N/A" }
    Write-Host "   -> Estado subsistemas: Database=$dbStatus, SicEngine=$sicStatus" -ForegroundColor DarkCyan
}

# 3. Probar documentación interactiva Swagger
Test-Endpoint -Name "/swagger" -Action {
    Invoke-WebRequest -Uri $swaggerUrl -Method Get -TimeoutSec 10 -UseBasicParsing | Out-Null
}

Write-Host "`n===========================================================" -f Cyan
Write-Host " [PASS] SMOKE TEST DE PRODUCCIÓN COMPLETADO CON ÉXITO" -f Green
Write-Host "===========================================================" -f Cyan