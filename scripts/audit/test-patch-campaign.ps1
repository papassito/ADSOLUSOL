<#
================================================================================
  ADSOLUSOL :: SUITE DE VALIDACION DE CONTROLADOR patchCampaign
  Verifica el cumplimiento estricto de las reglas de negocio y seguridad para
  la actualización de campañas.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$BaseUrl = "http://127.0.0.1:3000"
)

$ErrorActionPreference = "SilentlyContinue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Global:TestCounter = 0
$Global:AssertionsPassed = 0
$Global:AssertionsFailed = 0

function Write-Section([string]$Title) {
    Write-Host "`n==========================================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
}

function Assert-Call {
    param(
        [string]$TestName,
        [string]$Method,
        [string]$Uri,
        [object]$Body,
        [int]$ExpectedStatus,
        [string]$ExpectedError = ""
    )
    $Global:TestCounter++
    Write-Host "`n[TEST $($Global:TestCounter)] $TestName" -ForegroundColor White

    $response = $null
    $params = @{
        Method      = $Method
        Uri         = $Uri
        ContentType = 'application/json; charset=utf-8' # Explicitly set charset for PS 5.1
    }
    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Compress)
    }

    $errorBodyString = $null
    try {
        $response = Invoke-WebRequest @params -ErrorAction Stop
    } catch {
        $response = $_.Exception.Response
        # In PS 5.1, the error body must be read from the exception's response stream.
        try {
            $stream = $response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $errorBodyString = $reader.ReadToEnd()
            $reader.Close()
        } catch {
            # Fallback for when stream reading fails
            $errorBodyString = "Failed to read response stream: $($_.Exception.Message)"
        }
    }

    $actualStatus = if ($response) { [int]$response.StatusCode } else { 0 }

    if ($actualStatus -eq $ExpectedStatus) {
        Write-Host "  [PASS] Servidor respondió con $actualStatus." -ForegroundColor Green
        $Global:AssertionsPassed++
    } else {
        Write-Host "  [FAIL] Se esperaba status $ExpectedStatus pero se recibió $actualStatus." -ForegroundColor Red
        $Global:AssertionsFailed++
    }

    if (-not [string]::IsNullOrWhiteSpace($ExpectedError)) {
        $content = ""
        if ($errorBodyString) {
            try {
                $content = ($errorBodyString | ConvertFrom-Json -ErrorAction Stop).error
            } catch {
                $content = "No se pudo interpretar el cuerpo JSON del error: $errorBodyString"
            }
        } else {
            $content = "La respuesta de error no contenía un cuerpo legible."
        }

        if ($content -and $content -match $ExpectedError) {
            Write-Host "  [PASS] Mensaje de error esperado: '$($ExpectedError)'" -ForegroundColor Green
            $Global:AssertionsPassed++
        } else {
            Write-Host "  [FAIL] Se esperaba error '$ExpectedError' pero se recibió '$content'." -ForegroundColor Red
            $Global:AssertionsFailed++
        }
    }
    return $response
}

function Cleanup-TestCampaign($baseUrl, $campaignId) {
    if (-not $campaignId) { return }
    Write-Host "`n[CLEANUP] Eliminando campaña de prueba $campaignId..." -ForegroundColor DarkGray
    try {
        $null = Invoke-WebRequest -Method Delete -Uri "$baseUrl/api/campaigns/$campaignId" -ErrorAction Stop
    } catch {
        # Ignorar errores si la campaña ya no existe
    }
}

Write-Section "[TEST] SUITE DE VALIDACION PARA PATCH /api/campaigns/:id"

$uri = New-Object System.Uri($BaseUrl)
if (-not (Test-NetConnection -ComputerName $uri.Host -Port $uri.Port -InformationLevel Quiet)) {
    Write-Host "Error: El servidor de demo no está corriendo en $BaseUrl. Inícialo con 'npm run dev'." -ForegroundColor Red
    exit 1
}
Write-Host "Servidor de demo detectado en $BaseUrl... OK`n"

# --- Creación de campaña de prueba para aislamiento ---
$testCampaignId = "CAMP-TEST-" + [guid]::NewGuid().ToString().Substring(0,8)
$zeroSpentCampaignId = $null

try {
    Cleanup-TestCampaign $BaseUrl $testCampaignId # Limpieza previa por si quedó de una ejecución anterior
    $createBody = @{ id = $testCampaignId; name = "Campaña de Prueba"; budget = 100; spent = 50; clicks = 10; impressions = 1000 }
    Write-Host "[SETUP] Creando campaña de prueba aislada ($testCampaignId)..." -ForegroundColor DarkGray
    $null = Invoke-WebRequest -Method Post -Uri "$BaseUrl/api/campaigns" -Body ($createBody | ConvertTo-Json -Compress) -ContentType 'application/json; charset=utf-8'

    $campaign = ((Invoke-WebRequest -Uri "$BaseUrl/api/state").Content | ConvertFrom-Json).campaigns | Where-Object { $_.id -eq $testCampaignId }
    Write-Host "Estado inicial de la campaña de prueba:"
    Write-Host "- Name: $($campaign.name)"
    Write-Host "- Spent: $($campaign.spent)"
    Write-Host "- Impressions: $($campaign.impressions)"
    Write-Host "- Clicks: $($campaign.clicks)"

    # --- Pruebas de Rechazo (400 Bad Request) ---
    Write-Host "`n--- INICIANDO PRUEBAS DE RECHAZO ---" -ForegroundColor Yellow

    $null = Assert-Call "Rechazo de campo protegido 'spent'" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ spent = 999 } 400 "campo 'spent' es protegido"
    $null = Assert-Call "Rechazo de campo protegido 'impressions'" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ impressions = 9999 } 400 "campo 'impressions' es protegido"
    $null = Assert-Call "Rechazo de campo protegido 'clicks'" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ clicks = 100 } 400 "campo 'clicks' es protegido"
    $null = Assert-Call "Rechazo de campo protegido 'id'" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ id = "CAMP-NEW" } 400 "campo 'id' es protegido"

    $null = Assert-Call "Rechazo de presupuesto negativo" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ budget = -100 } 400 "estrictamente positivo"
    $null = Assert-Call "Rechazo de presupuesto no numérico" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ budget = "abc" } 400 "debe ser un número finito"
    $null = Assert-Call "Rechazo de presupuesto nulo" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ budget = $null } 400 "debe ser un número finito"
    $null = Assert-Call "Rechazo de presupuesto inferior al gasto" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ budget = 49 } 400 "no puede ser menor que el gasto actual"
    $null = Assert-Call "Rechazo de nombre de campaña inválido (muy corto)" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ name = "a" } 400 "debe ser una cadena entre 3 y 100"
    $null = Assert-Call "Rechazo de estado inválido" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ status = "INVALIDO" } 400 "debe ser uno de"
    $null = Assert-Call "Rechazo de estrategia inválida" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ strategy = "Estrategia Inexistente" } 400 "debe ser una de"

    # Prueba de presupuesto cero con gasto cero
    $zeroSpentCampaignId = "CAMP-TEST-ZERO-" + [guid]::NewGuid().ToString().Substring(0,8)
    Cleanup-TestCampaign $BaseUrl $zeroSpentCampaignId
    $createZeroBody = @{ id = $zeroSpentCampaignId; name = "Campaña Gasto Cero"; budget = 10; spent = 0 }
    $null = Invoke-WebRequest -Method Post -Uri "$BaseUrl/api/campaigns" -Body ($createZeroBody | ConvertTo-Json -Compress) -ContentType 'application/json; charset=utf-8'
    $null = Assert-Call "Rechazo de presupuesto cero (con gasto cero)" "PATCH" "$BaseUrl/api/campaigns/$zeroSpentCampaignId" @{ budget = 0 } 400 "estrictamente positivo"

    # --- Pruebas de Ruta ---
    Write-Host "`n--- INICIANDO PRUEBAS DE RUTA ---" -ForegroundColor Yellow
    $null = Assert-Call "Rechazo de campaña inexistente (404 NOT FOUND)" "PATCH" "$BaseUrl/api/campaigns/CAMP-NON-EXISTENT" @{ name = "Test" } 404 "no encontrada"

    # --- Pruebas de Actualización Válida ---
    Write-Host "`n--- INICIANDO PRUEBAS DE ACTUALIZACION VALIDA ---" -ForegroundColor Yellow
    $null = Assert-Call "Actualización válida de nombre y presupuesto" "PATCH" "$BaseUrl/api/campaigns/$testCampaignId" @{ name = "Campaña Validada"; budget = 200 } 200

    Write-Host "`n[TEST $($Global:TestCounter+1)] Verificación de estado post-actualización..." -ForegroundColor White
    $finalState = ((Invoke-WebRequest -Uri "$BaseUrl/api/state").Content | ConvertFrom-Json).campaigns | Where-Object { $_.id -eq $testCampaignId }

    if ($finalState.name -eq "Campaña Validada") { Write-Host "  [PASS] El campo 'name' fue actualizado a 'Campaña Validada'." -ForegroundColor Green; $Global:AssertionsPassed++ } else { Write-Host "  [FAIL] El campo 'name' no se actualizó (Recibido: $($finalState.name))." -ForegroundColor Red; $Global:AssertionsFailed++ }
    if ($finalState.budget -eq 200) { Write-Host "  [PASS] El campo 'budget' fue actualizado a 200." -ForegroundColor Green; $Global:AssertionsPassed++ } else { Write-Host "  [FAIL] El campo 'budget' no se actualizó." -ForegroundColor Red; $Global:AssertionsFailed++ }
    if ($finalState.spent -eq $campaign.spent) { Write-Host "  [PASS] El campo 'spent' permanece intacto ($($campaign.spent))." -ForegroundColor Green; $Global:AssertionsPassed++ } else { Write-Host "  [FAIL] El campo 'spent' fue modificado." -ForegroundColor Red; $Global:AssertionsFailed++ }
    if ($finalState.impressions -eq $campaign.impressions) { Write-Host "  [PASS] El campo 'impressions' permanece intacto ($($campaign.impressions))." -ForegroundColor Green; $Global:AssertionsPassed++ } else { Write-Host "  [FAIL] El campo 'impressions' fue modificado." -ForegroundColor Red; $Global:AssertionsFailed++ }
    if ($finalState.clicks -eq $campaign.clicks) { Write-Host "  [PASS] El campo 'clicks' permanece intacto ($($campaign.clicks))." -ForegroundColor Green; $Global:AssertionsPassed++ } else { Write-Host "  [FAIL] El campo 'clicks' fue modificado." -ForegroundColor Red; $Global:AssertionsFailed++ }

}
finally {
    Cleanup-TestCampaign $BaseUrl $testCampaignId
    Cleanup-TestCampaign $BaseUrl $zeroSpentCampaignId
}

Write-Section "RESULTADO: $($Global:AssertionsPassed) de $($Global:AssertionsPassed + $Global:AssertionsFailed) COMPROBACIONES APROBADAS"
if ($Global:AssertionsFailed -gt 0) {
    Write-Host "Se encontraron $($Global:AssertionsFailed) fallos." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Validación del controlador 'patchCampaign' completada exitosamente." -ForegroundColor Green
    exit 0
}