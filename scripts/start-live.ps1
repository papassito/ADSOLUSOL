<#
================================================================================
  ADSOLUSOL :: ORQUESTADOR DE ENTORNO LIVE (.NET API + Vite Frontend)
  Inicia y gestiona ambos procesos para un entorno de desarrollo real.
================================================================================
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$apiProject = "src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj"
$apiPort = 5000
$vitePort = 3000 # El puerto real puede variar si está ocupado
$apiProcess = $null
$viteProcess = $null

function Write-Section([string]$Title) {
    Write-Host "`n==========================================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
}

function Check-Port([int]$Port) {
    return try {
        Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    } catch {
        netstat -ano -p TCP | findstr "LISTENING" | findstr ":$Port"
    }
}

try {
    Write-Section "INICIANDO ENTORNO DE DESARROLLO LIVE (.NET + Vite)"

    if (Check-Port $apiPort) { throw "El puerto $apiPort (API .NET) ya está en uso." }
    Write-Host "[OK] Puerto $apiPort para la API está libre." -ForegroundColor Green

    Write-Host "`n[*] Iniciando API .NET en segundo plano (http://127.0.0.1:$apiPort)..."
    $apiArgs = "run --project `"$apiProject`" --urls `"http://127.0.0.1:$apiPort`""
    $apiProcess = Start-Process "dotnet" -ArgumentList $apiArgs -PassThru -WindowStyle Hidden
    Write-Host "  -> Proceso API iniciado con PID: $($apiProcess.Id)"

    Write-Host "  -> Esperando que la API responda en /health..." -NoNewline
    $apiReady = $false
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $res = Invoke-WebRequest -Uri "http://127.0.0.1:$apiPort/health" -UseBasicParsing -TimeoutSec 1
            if ($res.StatusCode -eq 200) { $apiReady = $true; Write-Host " OK!" -f Green; break }
        } catch { Write-Host "." -NoNewline; Start-Sleep -Milliseconds 500 }
    }
    if (-not $apiReady) { throw "La API .NET no respondió a tiempo." }

    Write-Host "`n[*] Iniciando servidor de desarrollo Vite (npm run dev:real)..."
    $viteProcess = Start-Process "npm" -ArgumentList "run", "dev:real" -PassThru
    Write-Host "`n[SUCCESS] Entorno LIVE iniciado. Accede a la UI en el puerto de Vite." -f Green
    Write-Host "           Presiona CTRL+C en esta ventana para detener ambos procesos."

    Wait-Process -Id $viteProcess.Id
}
catch {
    Write-Host "`n[ERROR] Ocurrió un error durante el arranque:" -f Red
    Write-Host $_.Exception.Message -f Red
}
finally {
    Write-Host "`n[*] Limpiando procesos en segundo plano..."
    if ($apiProcess -and -not $apiProcess.HasExited) {
        Write-Host "  -> Deteniendo API .NET (PID: $($apiProcess.Id))..."
        Stop-Process -Id $apiProcess.Id -Force
    }
    if ($viteProcess -and -not $viteProcess.HasExited) {
        Write-Host "  -> Deteniendo Vite (PID: $($viteProcess.Id))..."
        Stop-Process -Id $viteProcess.Id -Force
    }
    Write-Host "[OK] Limpieza completada."
}