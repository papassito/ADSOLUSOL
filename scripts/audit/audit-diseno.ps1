<#
================================================================================
  ADSOLUSOL :: AUDITORIA DE DISENO Y ARQUITECTURA ONION
  Evalua violaciones arquitectonicas, acoplamiento indebido, segregacion
  de capas y sanidad estructural de clases e interfaces.
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
Write-Host " [DISENO] AUDITORIA DE ARQUITECTURA ONION Y DISENO ESTRUCTURAL            " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$totalFallas = 0
$totalAdvertencias = 0

function Report-Falla([string]$Regla, [string]$Elemento, [string]$Mensaje) {
    Write-Host "  [FAIL] [$Regla] $Elemento -> $Mensaje" -ForegroundColor Red
    $script:totalFallas++
}

function Report-Warn([string]$Regla, [string]$Elemento, [string]$Mensaje) {
    Write-Host "  [WARN] [$Regla] $Elemento -> $Mensaje" -ForegroundColor Yellow
    $script:totalAdvertencias++
}

function Report-Pass([string]$Regla, [string]$Mensaje) {
    Write-Host "  [PASS] [$Regla] $Mensaje" -ForegroundColor Green
}

# 1. Validar pureza de la capa Domain (cero dependencias de infraestructura o presentación)
Write-Host "[1/4] Auditando pureza de la capa Domain..." -ForegroundColor Yellow
$domainFiles = Get-ChildItem -Path (Join-Path $ScriptRoot "src/ADSOLUSOL.Domain") -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue
$illegalDomainImports = @("Microsoft.AspNetCore", "Microsoft.EntityFrameworkCore", "Dapper", "System.Data.SqlClient", "Microsoft.Data.Sqlite")

$domainPurityFailures = 0
foreach ($f in $domainFiles) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    foreach ($imp in $illegalDomainImports) {
        if ($content -match "using\s+$imp") {
            Report-Falla "ONION-DOMAIN" $f.Name "La capa Domain contiene referencia prohibida a '$imp'."
            $domainPurityFailures++
        }
    }
}
if ($domainPurityFailures -eq 0) {
    Report-Pass "ONION-DOMAIN" "La capa Domain esta completamente libre de acoplamientos de infraestructura."
}

# 2. Validar que Application no dependa de implementaciones concretas de Infrastructure
Write-Host "`n[2/4] Auditando desacoplamiento de la capa Application..." -ForegroundColor Yellow
$appFiles = Get-ChildItem -Path (Join-Path $ScriptRoot "src/ADSOLUSOL.Application") -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue
$appCouplingFailures = 0
foreach ($f in $appFiles) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match "using\s+ADSOLUSOL\.Infrastructure") {
        Report-Falla "ONION-APP" $f.Name "Application no debe referenciar directamente a ADSOLUSOL.Infrastructure."
        $appCouplingFailures++
    }
}
if ($appCouplingFailures -eq 0) {
    Report-Pass "ONION-APP" "Application depende exclusivamente de abstracciones y contratos de dominio."
}

# 3. Deteccion de clases masivas / Dios (>500 lineas de codigo)
Write-Host "`n[3/4] Inspeccionando tamano y responsabilidad unica de clases C#..." -ForegroundColor Yellow
$allCsFiles = Get-ChildItem -Path (Join-Path $ScriptRoot "src") -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\/[\\/]' }

$largeClasses = 0
foreach ($cs in $allCsFiles) {
    $lines = [System.IO.File]::ReadAllLines($cs.FullName, [System.Text.Encoding]::UTF8)
    if ($lines.Length -gt 500) {
        Report-Warn "SRP-SIZE" $cs.Name "Clase potencialmente sobrecargada ($($lines.Length) lineas). Evaluar refactorizacion."
        $largeClasses++
    }
}
if ($largeClasses -eq 0) {
    Report-Pass "SRP-SIZE" "Todas las clases respetan limites canónicos de tamano de archivo."
}

# 4. Verificacion de contratos de Repositorio (Ausencia de retornos sync en interfaces)
Write-Host "`n[4/4] Verificando asincronia estricta en contratos de repositorio..." -ForegroundColor Yellow
$repoInterfaces = Get-ChildItem -Path (Join-Path $ScriptRoot "src/ADSOLUSOL.Domain/Interfaces") -Recurse -Filter "*Repository*.cs" -File -ErrorAction SilentlyContinue
$syncContractFailures = 0
foreach ($ri in $repoInterfaces) {
    $content = [System.IO.File]::ReadAllText($ri.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match "\b(void|int|long|bool|Campaign|Placement|Creative)\s+[A-Z]\w+Async\s*\(") {
        Report-Falla "CONTRACT-ASYNC" $ri.Name "Metodo asincrono no devuelve Task ni Task<T>."
        $syncContractFailures++
    }
}
if ($syncContractFailures -eq 0) {
    Report-Pass "CONTRACT-ASYNC" "Todas las interfaces de repositorio exigen firmas puramente asincronas (Task/Task<T>)."
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN DE DISENO ARQUITECTONICO                    " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Criticas : $totalFallas" -ForegroundColor $(if ($totalFallas -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias          : $totalAdvertencias" -ForegroundColor $(if ($totalAdvertencias -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($totalFallas -gt 0) {
    Write-Host "`n[FAIL] El diseno presenta infracciones directas a la arquitectura Onion.`n" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[PASS] La arquitectura de capas y el diseno cumplen con el estandar canonico.`n" -ForegroundColor Green
    exit 0
}