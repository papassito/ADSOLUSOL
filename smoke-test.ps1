[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Configuración ---
$baseUrl = "http://localhost:5000/api/marketing/adsolusol"
$apiKey = $env:Api__Key # Asume que la variable de entorno está configurada
$tenantId = $env:Api__TenantId # Asume que la variable de entorno está configurada

# --- Funciones de Ayuda ---
function Test-Endpoint {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host "🧪 Ejecutando prueba: $Name..." -ForegroundColor Yellow
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
            $body = $reader.ReadToEnd();
            Write-Host "   Response Body: $body" -ForegroundColor Red
        }
        # Terminar el script si una prueba crítica falla
        exit 1
    }
}

# --- Verificación Inicial ---
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Error "La variable de entorno 'Api__Key' no está configurada. Ejecuta: `$env:Api__Key = 'tu-clave'`"
    exit 1
}
Write-Host "===========================================================" -f Cyan
Write-Host " SMOKE TEST - VERIFICACIÓN DE ENDPOINTS EN EJECUCIÓN" -f Cyan
Write-Host "===========================================================" -f Cyan
Write-Host "Usando Tenant: $tenantId" -f Gray
Write-Host "Usando Base URL: $baseUrl`n" -f Gray


# --- Secuencia de Pruebas ---

# 1. Probar /health
Test-Endpoint -Name "/health" -Action {
    Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
}

# 2. Probar autenticación (X-Api-Key) - Inválida
Test-Endpoint -Name "Autenticación (X-Api-Key) - Inválida" -Action {
    try {
        Invoke-RestMethod -Uri "$baseUrl/campaigns" -Method Get -Headers @{"X-Api-Key" = "incorrecta"} -ErrorAction Stop
    } catch [System.Net.WebException] {
        if ($_.Exception.Response.StatusCode -eq 'Unauthorized') {
            # Esto es un éxito, se esperaba el error 401
            return "OK"
        }
        throw # Re-lanza la excepción si no es 401
    }
}

# 3. Crear una nueva campaña
$campaignName = "Campaña de Humo $((Get-Date).Ticks)"
$newCampaign = Test-Endpoint -Name "Crear Campaña (POST /campaigns)" -Action {
    $body = @{ name = $campaignName; budget = 100.0 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUrl/campaigns" -Method Post -Body $body -ContentType "application/json" -Headers @{"X-Api-Key" = $apiKey}
}
$campaignId = $newCampaign.id

# 4. Activar/Desactivar la campaña (toggle)
Test-Endpoint -Name "Activar/Desactivar Campaña (POST /toggle)" -Action {
    Invoke-RestMethod -Uri "$baseUrl/campaigns/$campaignId/toggle" -Method Post -Headers @{"X-Api-Key" = $apiKey} -Body $null
}

# 5. Registrar una impresión
Test-Endpoint -Name "Registrar Impresión (POST /impression)" -Action {
    Invoke-RestMethod -Uri "$baseUrl/campaigns/$campaignId/impression" -Method Post -Headers @{"X-Api-Key" = $apiKey} -Body $null
}

# 6. Registrar un clic
Test-Endpoint -Name "Registrar Clic (POST /click)" -Action {
    Invoke-RestMethod -Uri "$baseUrl/campaigns/$campaignId/click" -Method Post -Headers @{"X-Api-Key" = $apiKey} -Body $null
}

Write-Host "`n===========================================================" -f Cyan
Write-Host " ✅ SMOKE TEST COMPLETADO CON ÉXITO" -f Cyan
Write-Host "===========================================================" -f Cyan