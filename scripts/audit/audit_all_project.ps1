<#
================================================================================
  ADSOLUSOL :: AUDITORIA INTEGRAL TOTAL (AUDIT ALL PROJECT)
  Ejecuta en una sola sesion todos los auditores canonicos del sistema
  y genera un dictamen consolidado unificado.

  Uso:
    .\scripts\audit\audit_all_project.ps1
    .\scripts\audit\audit_all_project.ps1 -StopOnFail
    .\scripts\audit\audit_all_project.ps1 -Compact
    .\scripts\audit\audit_all_project.ps1 -Fast
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$StopOnFail,
    [switch]$Fast,
    [switch]$Compact
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
Write-Host " [SUITE MASTER] ADSOLUSOL :: AUDITORIA INTEGRAL DE TODO EL PROYECTO       " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot" -ForegroundColor DarkGray
Write-Host "Hora de Inicio : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor DarkGray

$AuditorPipeline = @(
    @{
        Fase = "Fase 1: Codificacion y Formato"
        Script = "scripts\audit\audit-unicode.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 1: Codificacion y Formato"
        Script = "scripts\audit\audit-mojibake.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 1: Codificacion y Formato"
        Script = "scripts\audit\radiografia_codigo.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 1: Codificacion y Formato"
        Script = "scripts\audit\Verificar-Errores.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 2: Arquitectura y Dominio"
        Script = "scripts\audit\audit-diseno.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 2: Arquitectura y Dominio"
        Script = "scripts\audit\audit-dominio.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 2: Arquitectura y Dominio"
        Script = "scripts\audit\audit-tree.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 2: Arquitectura y Dominio"
        Script = "scripts\audit\CALIFICADOR_MODULOS.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 3: Seguridad y Notaria"
        Script = "scripts\audit\audit-seguridad.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 3: Seguridad y Notaria"
        Script = "scripts\audit\autopsia_integridad.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 4: Compilacion y Carga"
        Script = "scripts\audit\audit-compilacion.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 4: Compilacion y Carga"
        Script = "scripts\audit\audit-concurrencia.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 4: Compilacion y Carga"
        Script = "scripts\audit\test-stress.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 5: Quality Gate Integral"
        Script = "scripts\audit\radiologico_forense.ps1"
        Args = @()
    },
    @{
        Fase = "Fase 5: Quality Gate Integral"
        Script = "scripts\audit\junta_medica.ps1"
        Args = $(if ($Fast) { @("-Fast") } else { @() })
    },
    @{
        Fase = "Fase 5: Quality Gate Integral"
        Script = "scripts\audit\audit-live.ps1"
        Args = @()
    }
)

$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
$psExe = if ($pwshCmd) { $pwshCmd.Source } else { "powershell.exe" }

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()
$TotalTimer = [System.Diagnostics.Stopwatch]::StartNew()
$Fails = 0
$Warns = 0

foreach ($item in $AuditorPipeline) {
    $path = Join-Path $ScriptRoot $item.Script
    $name = Split-Path -Leaf $item.Script

    Write-Host "`n>>> [$($item.Fase)] -> $name" -ForegroundColor Yellow

    if (-not (Test-Path $path)) {
        Write-Host "  [FAIL] Script no encontrado: $($item.Script)" -ForegroundColor Red
        $Results.Add([PSCustomObject]@{ Fase = $item.Fase; Auditor = $name; ExitCode = 1; Dictamen = "FAIL"; Duracion = "0.0s" })
        $Fails++
        if ($StopOnFail) { break }
        continue
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $callArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $path) + $item.Args
    if ($Compact) {
        $subOut = & $psExe $callArgs 2>&1
    } else {
        & $psExe $callArgs
    }
    $exit = $LASTEXITCODE
    $sw.Stop()

    $dur = "$([math]::Round($sw.Elapsed.TotalSeconds, 2))s"
    $dictamen = if ($exit -eq 0) { "PASS" } elseif ($exit -eq 2) { "WARN" } else { "FAIL" }
    if ($dictamen -eq "FAIL") { $Fails++ }
    if ($dictamen -eq "WARN") { $Warns++ }

    $Results.Add([PSCustomObject]@{ Fase = $item.Fase; Auditor = $name; ExitCode = $exit; Dictamen = $dictamen; Duracion = $dur })
    
    if ($Compact) {
        Write-Host "   -> Resultado: [$dictamen] ($dur)" -ForegroundColor $(if ($dictamen -eq "PASS") { "Green" } elseif ($dictamen -eq "WARN") { "Yellow" } else { "Red" })
    }

    if ($dictamen -eq "FAIL" -and $StopOnFail) {
        Write-Host "`n[INTERRUPCION] Deteniendo suite anticipadamente por fallo (-StopOnFail)." -ForegroundColor Red
        break
    }
}

$TotalTimer.Stop()

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                RESUMEN DE AUDITORIA INTEGRAL DEL PROYECTO                " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
$Results | Format-Table Fase, Auditor, Dictamen, ExitCode, Duracion -AutoSize

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Total Auditores Ejecutados : $($Results.Count) / $($AuditorPipeline.Count)" -ForegroundColor White
Write-Host " Auditores en PASS          : $($Results.Count - $Fails - $Warns)" -ForegroundColor Green
Write-Host " Auditores con WARN         : $Warns" -ForegroundColor Yellow
Write-Host " Auditores en FAIL          : $Fails" -ForegroundColor $(if ($Fails -eq 0) { "Green" } else { "Red" })
Write-Host " Tiempo Total Invertido     : $([math]::Round($TotalTimer.Elapsed.TotalSeconds, 2)) s" -ForegroundColor DarkCyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($Fails -gt 0) { exit 1 } else { exit 0 }