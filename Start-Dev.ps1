# Start-Dev.ps1 - Orquestador de desarrollo sin bloqueos
$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    LIMPIEZA DE PROCESOS Y ARRANQUE DE ADSOLUSOL  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Detener instancias activas de la API
Write-Host "[1/2] Liberando bloqueos de archivos DLL..." -ForegroundColor Yellow
Get-Process -Name "ADSOLUSOL.Presentation.Api" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# 2. Iniciar la API con dotnet watch (compilación automática sin bloquéos)
Write-Host "[2/2] Iniciando API en modo Hot-Reload (dotnet watch)..." -ForegroundColor Green
Set-Location "Y:\Documentos\GitHub\ADSOLUSOL\src\ADSOLUSOL.Presentation.Api"
dotnet watch run -c Release
