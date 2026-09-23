[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot = (Get-Location).Path
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    LIMPIEZA DE PROCESOS Y ARRANQUE DE ADSOLUSOL  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$desktopProjectDir = "src\ADSOLUSOL.Presentation.Desktop"
$desktopProcessName = "ADSOLUSOL.Presentation.Desktop"
$desktopFullPath = Join-Path $PSScriptRoot $desktopProjectDir

Write-Host "[1/2] Liberando bloqueos de archivos DLL..." -ForegroundColor Yellow
Get-Process -Name $desktopProcessName -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "VBCSCompiler" -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep -Seconds 1
Write-Host "  [OK] Procesos liberados correctamente." -ForegroundColor Green

Write-Host "[2/2] Iniciando App Nativa en modo Hot-Reload (dotnet watch)..." -ForegroundColor Yellow
if (-not (Test-Path $desktopFullPath)) {
    Write-Error "No se encontró el directorio del proyecto de escritorio en: $desktopFullPath"
    exit 1
}
Set-Location $desktopFullPath
dotnet watch run -c Debug
