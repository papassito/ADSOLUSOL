﻿[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    LIMPIEZA DE PROCESOS Y ARRANQUE DE ADSOLUSOL  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$apiProjectDir = "src\ADSOLUSOL.Presentation.Api"
$apiProcessName = "ADSOLUSOL.Presentation.Api"
$apiFullPath = Join-Path $PSScriptRoot $apiProjectDir

Write-Host "[1/2] Liberando bloqueos de archivos DLL..." -ForegroundColor Yellow
Get-Process -Name $apiProcessName -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "VBCSCompiler" -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep -Seconds 1
Write-Host "  [OK] Procesos liberados correctamente." -ForegroundColor Green

Write-Host "[2/2] Iniciando API en modo Hot-Reload (dotnet watch)..." -ForegroundColor Yellow
if (-not (Test-Path $apiFullPath)) {
    Write-Error "No se encontró el directorio del proyecto API en: $apiFullPath"
    exit 1
}
Set-Location $apiFullPath
dotnet watch run -c Release
