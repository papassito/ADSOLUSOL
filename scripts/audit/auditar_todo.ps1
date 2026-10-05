<#
================================================================================
  ADSOLUSOL :: ORQUESTADOR MAESTRO DE AUDITORIA FORENSE Y CALIDAD (.NET 8)
  Ejecuta secuencialmente la suite completa de auditores canónicos sin omisiones.
  Uso:
    .\scripts\audit\auditar_todo.ps1
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
Write-Host " [SUITE] ADSOLUSOL :: ORQUESTADOR MAESTRO DE AUDITORIA FORENSE           " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$AuditorFiles = @(
    "scripts\audit\audit-compilacion.ps1",
    "scripts\audit\audit-concurrencia.ps1",
    "scripts\audit\audit-diseno.ps1",
    "scripts\audit\audit-dominio.ps1",
    "scripts\audit\audit-seguridad.ps1",
    "scripts\audit\audit-unicode.ps1",
    "scripts\audit\audit-mojibake.ps1",
    "scripts\audit\audit-tree.ps1",
    "scripts\audit\CALIFICADOR_MODULOS.ps1",
    "scripts\audit\autopsia_integridad.ps1",
    "scripts\audit\junta_medica.ps1",
    "scripts\audit\audit-live.ps1"
)

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()
$FailedCount = 0
$WarnCount = 0
$TotalSw = [System.Diagnostics.Stopwatch]::StartNew()

$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
$psExe = if ($pwshCmd) { $pwshCmd.Source } else { "powershell.exe" }

foreach ($scriptRel in $AuditorFiles) {
    $scriptPath = Join-Path $ScriptRoot $scriptRel
    $auditorName = Split-Path -Leaf $scriptRel
    Write-Host "`n>>> [EJECUTANDO AUDITOR: $auditorName] ..." -ForegroundColor Yellow

    if (-not (Test-Path $scriptPath)) {
        Write-Host "  [FAIL] Script obligatorio no encontrado: $scriptRel" -ForegroundColor Red
        $Results.Add([PSCustomObject]@{
            Auditor  = $auditorName
            Ruta     = $scriptRel
            ExitCode = 1
            Dictamen = "FAIL"
            Duracion = "0.0s"
        })
        $FailedCount++
        continue
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $psExe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
    $exitCode = $LASTEXITCODE
    $sw.Stop()
    $durationStr = "$([math]::Round($sw.Elapsed.TotalSeconds, 2))s"

    $dictamen = if ($exitCode -eq 0) { "PASS" } elseif ($exitCode -eq 2) { "WARN" } else { "FAIL" }
    if ($dictamen -eq "FAIL") { $FailedCount++ }
    if ($dictamen -eq "WARN") { $WarnCount++ }

    $Results.Add([PSCustomObject]@{
        Auditor  = $auditorName
        Ruta     = $scriptRel
        ExitCode = $exitCode
        Dictamen = $dictamen
        Duracion = $durationStr
    })
}

$TotalSw.Stop()

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                 TABLA CONSOLIDADA DE AUDITORES EJECUTADOS                " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
$Results | Format-Table Auditor, Dictamen, ExitCode, Duracion, Ruta -AutoSize

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Total Auditores Ejecutados : $($Results.Count) / $($AuditorFiles.Count)" -ForegroundColor White
Write-Host " Auditores en PASS          : $($Results.Count - $FailedCount - $WarnCount)" -ForegroundColor Green
Write-Host " Auditores con WARN         : $WarnCount" -ForegroundColor Yellow
Write-Host " Auditores en FAIL          : $FailedCount" -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })
Write-Host " Tiempo Total de Suite      : $([math]::Round($TotalSw.Elapsed.TotalSeconds, 2))s" -ForegroundColor DarkCyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($FailedCount -gt 0) {
    Write-Host "`n[FAIL] La suite de auditoria detecto fallas en $FailedCount auditor(es).`n" -ForegroundColor Red
    exit 1
} elseif ($WarnCount -gt 0) {
    Write-Host "`n[PASS CON OBSERVACIONES] Todos los auditores obligatorios pasaron sin fallas criticas.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] TODOS LOS AUDITORES EJECUTADOS Y APROBADOS SATISFACTORIAMENTE.`n" -ForegroundColor Green
    exit 0
}