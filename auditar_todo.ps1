<#
================================================================================
  REPAIRER by KLIK :: ORQUESTADOR MAESTRO DE AUDITORÍAS TOTALES
  Ejecuta toda la suite de auditores periciales, métricas y calidad.
================================================================================
#>
[CmdletBinding()]
param(
    [switch]$Fix,
    [switch]$Fast
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$root = if ($PSScriptRoot) { (Resolve-Path $PSScriptRoot).Path } else { (Resolve-Path (Get-Location).Path).Path }
Set-Location $root

# Evitar pausas interactivas en scripts secundarios durante la corrida masiva
$env:CI = "true"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [REPAIRER by KLIK] PROTOCOLO MAESTRO DE AUDITORIA Y CONTROL TOTAL" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Ruta de Inspección : $root" -ForegroundColor DarkGray
Write-Host "Opciones Activas   : Fix=$($Fix.IsPresent) | Fast=$($Fast.IsPresent)" -ForegroundColor DarkGray
Write-Host ""

$auditors = @(
    @{
        Name   = "1. Estructura y Fronteras ADR-009"
        Script = "check_structure.ps1"
        Args   = @()
    },
    @{
        Name   = "2. Chismoso CI/CD (Formato, Race & Build)"
        Script = "chismoso.ps1"
        Args   = @(if ($Fix) { "-Fix" }; if ($Fast) { "-Fast" })
    },
    @{
        Name   = "3. Autopsia de Integridad y Notaría Documental"
        Script = "autopsia_integridad.ps1"
        Args   = @()
    },
    @{
        Name   = "4. Calificador Numérico Modular (.NET 8 / C#)"
        Script = "CALIFICADOR_MODULOS.ps1"
        Args   = @()
    },
    @{
        Name   = "5. Salud del Proyecto (Stack & Entorno)"
        Script = "Calificar-Proyecto.ps1"
        Args   = @()
    },
    @{
        Name   = "6. Ultra-Mitotero v4.0 (Ledger, Red, EDR)"
        Script = "audit_ultra-mitotero.ps1"
        Args   = @()
    },
    @{
        Name   = "7. Junta Médica Suprema Forense (11/11)"
        Script = "junta_medica.ps1"
        Args   = @(if ($Fix) { "-Fix" }; if ($Fast) { "-Fast" })
    }
)

$results = @()
$hasGlobalFailures = $false

foreach ($item in $auditors) {
    $scriptPath = Join-Path $root $item.Script
    if (-not (Test-Path $scriptPath)) {
        $scriptPath = Join-Path (Join-Path $root "scripts") $item.Script
    }
    if (-not (Test-Path $scriptPath)) {
        Write-Host "`n[OMITIDO] Script $($item.Script) no encontrado." -ForegroundColor Yellow
        continue
    }

    Write-Host "`n==========================================================================" -ForegroundColor Yellow
    Write-Host " [EJECUTANDO] $($item.Name) :: $($item.Script)" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Yellow

    $startStep = [System.Diagnostics.Stopwatch]::StartNew()
    $callArgs = @($item.Args)
    & $scriptPath @callArgs
    $exitCode = $LASTEXITCODE
    $startStep.Stop()
    $duration = [math]::Round($startStep.Elapsed.TotalSeconds, 2)

    $passed = ($exitCode -eq 0)
    if (-not $passed) {
        $hasGlobalFailures = $true
    }

    $results += [PSCustomObject]@{
        Auditor   = $item.Name
        Script    = $item.Script
        Resultado = if ($passed) { "PASS" } else { "FAIL" }
        TiempoSeg = $duration
    }
}

$stopwatch.Stop()
$totalElapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "            TABLERO RESUMEN DE AUDITORIAS (TOTAL: ${totalElapsed}s)" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$results | Format-Table Auditor, Script, Resultado, TiempoSeg -AutoSize

if ($hasGlobalFailures) {
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Red
    Write-Host "[FAIL] SE DETECTARON ANOMALIAS EN UNO O MAS AUDITORES." -ForegroundColor Red
    Write-Host "Sugerencia: Revisa los logs superiores o corre con '.\auditar_todo.ps1 -Fix'." -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
    Write-Host "[PASS] ALTA TOTAL: TODOS LOS AUDITORES PASARON SATISFACTORIAMENTE." -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 0
}