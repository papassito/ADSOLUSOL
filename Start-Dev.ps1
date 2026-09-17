$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    LIMPIEZA DE PROCESOS Y ARRANQUE DE ADSOLUSOL  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "[1/2] Liberando bloqueos de archivos DLL..." -ForegroundColor Yellow
Get-Process -Name "ADSOLUSOL.Presentation.Api" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "VBCSCompiler" -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep -Seconds 1
Write-Host "  [OK] Procesos liberados correctamente." -ForegroundColor Green

Write-Host "[2/2] Iniciando API en modo Hot-Reload (dotnet watch)..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\src\ADSOLUSOL.Presentation.Api"
dotnet watch run -c Release
