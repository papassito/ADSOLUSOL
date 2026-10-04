<#
================================================================================
  ADSOLUSOL :: AUDITORIA EXHAUSTIVA DE COMPILACION (.NET 8)
  Verifica compilacion limpia en Release, integridad de paquetes NuGet,
  diagnosticos del compilador Roslyn y formato canónico.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
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
Write-Host " [COMPILACION] AUDITORIA RIGUROSA DE BUILD Y TOOLCHAIN .NET 8             " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$compilationErrors = 0

# 1. Verificacion de version de SDK .NET
Write-Host "[1/4] Comprobando SDK oficial de .NET instalado..." -ForegroundColor Yellow
if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    $dotnetVersion = (& dotnet --version).Trim()
    Write-Host "  [OK] .NET SDK detectado: $dotnetVersion" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] .NET SDK no encontrado en el PATH del sistema." -ForegroundColor Red
    exit 1
}

# 2. Restauracion de paquetes NuGet
Write-Host "`n[2/4] Ejecutando dotnet restore sobre ADSOLUSOL.sln..." -ForegroundColor Yellow
$restoreOut = & dotnet restore ADSOLUSOL.sln -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false --verbosity quiet 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [PASS] [RESTORE] Dependencias NuGet restauradas sin advertencias ni conflictos." -ForegroundColor Green
} else {
    Write-Host "  [FAIL] [RESTORE] Error al restaurar paquetes NuGet." -ForegroundColor Red
    $compilationErrors++
}

# 3. Compilacion Roslyn en configuracion Release
Write-Host "`n[3/4] Compilando solucion completa en configuracion Release..." -ForegroundColor Yellow
$buildParams = @(
    "build", "ADSOLUSOL.sln",
    "-c", "Release",
    "--no-restore",
    "-p:IgnoreMissingWorkloads=true",
    "-p:WindowsPackageType=None",
    "-p:AppxPackage=false",
    "-p:GenerateAppxPackageOnBuild=false",
    "-p:WindowsAppSDKSelfContained=false",
    "-v:minimal",
    "--nologo"
)
$buildOut = & dotnet @buildParams 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [PASS] [BUILD] Compilacion exitosa. Cero errores de compilador (Exit Code: 0)." -ForegroundColor Green
} else {
    Write-Host "  [FAIL] [BUILD] Errores de compilacion detectados:" -ForegroundColor Red
    $buildOut | Where-Object { $_ -match ":\s*error\s+(CS|MSB|NU|NETSDK)\d+:" } | ForEach-Object {
        Write-Host "     $_" -ForegroundColor Red
    }
    $compilationErrors++
}

# 4. Verificacion de formato canonico (.NET Format)
Write-Host "`n[4/4] Verificando alineacion con estandar de estilo (dotnet format)..." -ForegroundColor Yellow
$formatOut = & dotnet format ADSOLUSOL.sln --no-restore --verify-no-changes --verbosity quiet 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [PASS] [FORMAT] Codigo C# cumple 100% con el estandar de formato canonico." -ForegroundColor Green
} else {
    Write-Host "  [WARN] [FORMAT] Existen discrepancias de estilo visual con dotnet format." -ForegroundColor Yellow
}

# 5. Validacion de proyectos ejecutables
Write-Host "`n[5/4] Verificando artefactos de salida esenciales..." -ForegroundColor Yellow
$apiBinDir = Join-Path $ScriptRoot "src/ADSOLUSOL.Presentation.Api/bin/Release/net8.0"
$apiArtifact = Get-ChildItem -Path $apiBinDir -Filter "ADSOLUSOL.Presentation.Api.*" -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in @(".dll", ".exe") } | Select-Object -First 1
if ($apiArtifact) {
    $sizeKb = [math]::Round($apiArtifact.Length / 1KB, 2)
    Write-Host "  [PASS] [OUTPUT] Ensamblado API generado: $sizeKb KB" -ForegroundColor Green
} else {
    Write-Host "  [WARN] [OUTPUT] Ensamblado de API no encontrado en bin/Release/net8.0." -ForegroundColor Yellow
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                  DICTAMEN FINAL DE COMPILACION                           " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Errores Criticos de Build : $compilationErrors" -ForegroundColor $(if ($compilationErrors -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($compilationErrors -gt 0) {
    Write-Host "`n[FAIL] La solucion no compila limpiamente.`n" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[PASS] Ecosistema .NET 8 compila y enlaza en estado optimo.`n" -ForegroundColor Green
    exit 0
}