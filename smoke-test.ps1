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
$livenessUrl = "$($BaseUrl.TrimEnd('/'))/health"
$baseApiUrl = "$($BaseUrl.TrimEnd('/'))/api"
$healthUrl = "$($BaseUrl.TrimEnd('/'))/api/health"

# Test identity corresponding to the mock NodeRegistry
$nodeId = "NODE_ADS_01"
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# Load NSec for signing from the application's build output directory
$publishDir = Join-Path $scriptRoot "BUILD\ADSOLUSOL"
$nsecDllPath = Join-Path $publishDir "NSec.Cryptography.dll"

if (-not (Test-Path $nsecDllPath)) {
    $apiPublishDir = Join-Path $scriptRoot "BUILD\Api"
    if (Test-Path (Join-Path $apiPublishDir "NSec.Cryptography.dll")) {
        $nsecDllPath = Join-Path $apiPublishDir "NSec.Cryptography.dll"
    }
}

if (-not (Test-Path $nsecDllPath)) {
    $fallbackDll = Get-ChildItem -Path @((Join-Path $scriptRoot ".build"), (Join-Path $scriptRoot "src")) -Filter "NSec.Cryptography.dll" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($fallbackDll) { $nsecDllPath = $fallbackDll.FullName }
}

$hasCrypto = $false
$privateKeyHex = $env:ADS_SMOKE_TEST_KEY

if (Test-Path $nsecDllPath) {
    try {
        if (-not ([System.Management.Automation.PSTypeName]'NSec.Cryptography.SignatureAlgorithm').Type) {
            # Desbloquear archivo en Windows si contiene Mark of the Web
            try { Unblock-File -Path $nsecDllPath -ErrorAction SilentlyContinue } catch {}
            
            # Cargar libsodium nativo si existe en la misma carpeta para resolver dependencias P/Invoke
            $nativeSodium = Join-Path (Split-Path $nsecDllPath -Parent) "libsodium.dll"
            if (Test-Path $nativeSodium) {
                try { Unblock-File -Path $nativeSodium -ErrorAction SilentlyContinue } catch {}
                if ([Type]::GetType("System.Runtime.InteropServices.NativeLibrary")) {
                    [System.Runtime.InteropServices.NativeLibrary]::Load($nativeSodium) | Out-Null
                } elseif (-not ([System.Management.Automation.PSTypeName]'Win32Kernel').Type) {
                    Add-Type -MemberDefinition '[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)] public static extern IntPtr LoadLibrary(string lpFileName);' -Name "Win32Kernel" -Namespace "NativeWin32" -ErrorAction SilentlyContinue
                    if ([Type]::GetType("NativeWin32.Win32Kernel")) {
                        [NativeWin32.Win32Kernel]::LoadLibrary($nativeSodium) | Out-Null
                    }
                }
            }

            # Carga por bytes para evitar HRESULT: 0x80131515 (zonas de seguridad .NET)
            $bytes = [System.IO.File]::ReadAllBytes($nsecDllPath)
            [System.Reflection.Assembly]::Load($bytes) | Out-Null
        }
        $hasCrypto = [bool]([System.Management.Automation.PSTypeName]'NSec.Cryptography.SignatureAlgorithm').Type
    }
    catch {
        $hasCrypto = $false
        Write-Warning "No se pudo cargar NSec.Cryptography.dll: $($_.Exception.Message)"
    }
} else {
    $hasCrypto = $false
}

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
    $cleanHex = $privateKeyHex.Trim()
    $privateKeyBytes = [byte[]]::new($cleanHex.Length / 2)
    for ($i = 0; $i -lt $cleanHex.Length; $i += 2) {
        $privateKeyBytes[$i / 2] = [Convert]::ToByte($cleanHex.Substring($i, 2), 16)
    }

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

# 1. Probar /health (Liveness de Kestrel)
Test-Endpoint -Name "/health" -Action {
    Invoke-RestMethod -Uri $livenessUrl -Method Get
}

# 2. Probar /api/health (Integración profunda SQLite + SIC)
Test-Endpoint -Name "/api/health" -Action {
    Invoke-RestMethod -Uri $healthUrl -Method Get
}

if (-not $hasCrypto -or [string]::IsNullOrWhiteSpace($privateKeyHex)) {
    Write-Host "`n[AVISO] Se omiten pruebas autenticadas (POST /api/Campaigns):" -ForegroundColor Yellow
    Write-Host "  -> Configure `$env:ADS_SMOKE_TEST_KEY y compile la solucion para ejecutar mutaciones con firma Ed25519." -ForegroundColor DarkGray
    Write-Host "`n===========================================================" -f Cyan
    Write-Host " [PASS] SMOKE TEST DE SALUD Y CONECTIVIDAD COMPLETADO" -f Green
    Write-Host "===========================================================" -f Cyan
    exit 0
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