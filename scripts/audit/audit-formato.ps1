<#
================================================================================
  ADSOLUSOL :: AUDITORIA PERICIAL DE FORMATO CANONICO (.NET FORMAT)
  Fiscaliza el estilo visual, espacios en blanco, convenciones de nombres
  y reglas de formato Roslyn oficiales sobre la solución ADSOLUSOL.sln.

  Uso:
    .\scripts\audit\audit-formato.ps1          # Solo lectura / Verificación
    .\scripts\audit\audit-formato.ps1 -Fix     # Auto-formatear archivos
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$Fix
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [FORMATO] AUDITORIA DE ESTILO Y FORMATO CANONICO (.NET FORMAT)           " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "  [FAIL] dotnet SDK no disponible en PATH." -ForegroundColor Red
    exit 1
}

Write-Host "[1/2] Verificando restauración de dependencias..." -ForegroundColor Yellow
& dotnet restore "ADSOLUSOL.sln" --verbosity quiet -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false 2>&1 | Out-Null

if ($Fix) {
    Write-Host "`n[2/2] Aplicando auto-formateo (.NET Format -Fix)..." -ForegroundColor Yellow
    $formatFixOut = & dotnet format "ADSOLUSOL.sln" --no-restore -v:minimal 2>&1
    Write-Host "  [INFO] Auto-formateo ejecutado." -ForegroundColor Gray
}

Write-Host "`n[2/2] Auditando cumplimiento estricto con dotnet format --verify-no-changes..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$formatOut = & dotnet format "ADSOLUSOL.sln" --no-restore --verify-no-changes --verbosity minimal 2>&1
$exitCode = $LASTEXITCODE
$sw.Stop()

$rawLines = @($formatOut | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ -ne "" })
$whitespaceErrors = @($rawLines | Where-Object { $_ -match "error\s+WHITESPACE:" })
$styleErrors      = @($rawLines | Where-Object { $_ -match "error\s+(IDE|CS)\d+:" })

$totalErrors = $whitespaceErrors.Count + $styleErrors.Count

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                 DICTAMEN DE FORMATO CANONICO (.NET FORMAT)               " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Tiempo de Verificación : $([math]::Round($sw.Elapsed.TotalSeconds, 2))s" -ForegroundColor DarkGray
Write-Host " Errores WHITESPACE     : $($whitespaceErrors.Count)" -ForegroundColor $(if ($whitespaceErrors.Count -eq 0) { "Green" } else { "Red" })
Write-Host " Errores de Estilo IDE  : $($styleErrors.Count)" -ForegroundColor $(if ($styleErrors.Count -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($exitCode -eq 0 -and $totalErrors -eq 0) {
    Write-Host "`n  [PASS 10/10] Agudeza visual 20/20: Todo el código C# cumple con el estándar canónico oficial.`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n  [FAIL] Se detectaron discrepancias de formato de código:" -ForegroundColor Red
    foreach ($err in $whitespaceErrors) {
        Write-Host "     [WHITESPACE] $err" -ForegroundColor Red
    }
    foreach ($err in $styleErrors) {
        Write-Host "     [STYLE]      $err" -ForegroundColor Yellow
    }
    Write-Host "`n  Tip de remediación: Ejecuta '.\scripts\audit\audit-formato.ps1 -Fix' para auto-reparar.`n" -ForegroundColor Yellow
    exit 1
}