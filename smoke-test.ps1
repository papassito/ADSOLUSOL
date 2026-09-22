﻿﻿[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Configuration ---
$baseApiUrl = "http://localhost:5000/api"
$healthUrl = "http://localhost:5000/api/health"

# Test identity corresponding to the mock NodeRegistry
$nodeId = "NODE_ADS_01"
$privateKeyHex = $env:ADS_SMOKE_TEST_KEY

if ([string]::IsNullOrWhiteSpace($privateKeyHex)) {
    Write-Error "La variable de entorno 'ADS_SMOKE_TEST_KEY' no está configurada. No se puede firmar las solicitudes."
    exit 1
}

# Load NSec for signing from the application's build output directory
$publishDir = Join-Path $PSScriptRoot "BUILD\ADSOLUSOL"
$nsecDllPath = Join-Path $publishDir "NSec.Cryptography.dll"

if (-not (Test-Path $nsecDllPath)) {
    Write-Error "NSec.Cryptography.dll not found in build output directory '$publishDir'. Please run BUILD-ADSOLUSOL.ps1 first."
    exit 1
}
try { Add-Type -Path $nsecDllPath }
catch { Write-Error "NSec.Cryptography.dll not found. Please ensure it's available or adjust the path."; exit 1 }


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

function Get-AuthHeaders {
    param(
        [string]$method,
        [string]$path,
        [string]$query = "",
        [string]$body = ""
    )
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $nonce = [Guid]::NewGuid().ToString("N")

    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bodyHash = if ($bodyBytes.Length -eq 0) { "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" } else { [System.BitConverter]::ToString($sha256.ComputeHash($bodyBytes)).Replace("-", "").ToLower() }

    $canonicalString = "$timestamp|$nonce|$method|$path|$query|$bodyHash"
    $dataToSign = [System.Text.Encoding]::UTF8.GetBytes($canonicalString)
    $privateKeyBytes = [System.Convert]::FromHexString($privateKeyHex)

    $algorithm = [NSec.Cryptography.SignatureAlgorithm]::Ed25519
    $key = [NSec.Cryptography.Key]::Import($algorithm, $privateKeyBytes, [NSec.Cryptography.KeyBlobFormat]::RawPrivateKey)
    $signatureBytes = $algorithm.Sign($key, $dataToSign)
    $signatureBase64 = [System.Convert]::ToBase64String($signatureBytes)

    return @{
        "X-Solusol-Node-Id"   = $nodeId
        "X-Solusol-Timestamp" = $timestamp
        "X-Solusol-Nonce"     = $nonce
        "X-Solusol-Signature" = $signatureBase64
    }
}

Write-Host "===========================================================" -f Cyan
Write-Host " SMOKE TEST - VERIFICACIÓN DE ENDPOINTS EN EJECUCIÓN" -f Cyan
Write-Host "===========================================================" -f Cyan
Write-Host "Usando Node ID: $nodeId" -f Gray
Write-Host "Usando Base URL: $baseApiUrl`n" -f Gray


# --- Secuencia de Pruebas ---

# 1. Probar /health
Test-Endpoint -Name "/health" -Action {
    Invoke-RestMethod -Uri $healthUrl -Method Get
}

# 2. Probar autenticación - Inválida
Test-Endpoint -Name "Autenticación (Firma Inválida)" -Action {
    try {
        $headers = Get-AuthHeaders -method "GET" -path "/api/Campaigns"
        $headers["X-Solusol-Signature"] = "invalidsignature"
        Invoke-RestMethod -Uri "$baseApiUrl/Campaigns" -Method Get -Headers $headers -ErrorAction Stop
    } catch [System.Net.WebException] {
        if ($_.Exception.Response.StatusCode -eq 'Forbidden') {
            # Esto es un éxito, se esperaba el error 403
            return "OK"
        }
        throw # Re-lanza la excepción si no es 401
    }
}

# 3. Crear una nueva campaña (POST /api/Campaigns)
$campaignName = "Campaña de Humo $((Get-Date).Ticks)"
$createBody = @{ name = $campaignName; budget = 100.0; costPerMille = 1.5; costPerClick = 0.25 } | ConvertTo-Json
$createHeaders = Get-AuthHeaders -method "POST" -path "/api/Campaigns" -body $createBody
$newCampaign = Test-Endpoint -Name "Crear Campaña (POST /campaigns)" -Action {
    Invoke-RestMethod -Uri "$baseApiUrl/Campaigns" -Method Post -Body $createBody -ContentType "application/json" -Headers $createHeaders
}
$campaignId = $newCampaign.id

# 4. Activar la campaña
$statusBody = @{ status = "ACTIVE" } | ConvertTo-Json
$statusHeaders = Get-AuthHeaders -method "POST" -path "/api/Campaigns/$campaignId/status" -body $statusBody
Test-Endpoint -Name "Activar Campaña (POST /status)" -Action {
    Invoke-RestMethod -Uri "$baseApiUrl/Campaigns/$campaignId/status" -Method Post -Headers $statusHeaders -Body $statusBody -ContentType "application/json"
}

Write-Host "`n===========================================================" -f Cyan
Write-Host " ✅ SMOKE TEST COMPLETADO CON ÉXITO" -f Cyan
Write-Host "===========================================================" -f Cyan