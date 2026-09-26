[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="El mensaje para el commit es obligatorio.")]
    [string]$CommitMessage,
    [switch]$SkipAudit,
    [string]$SkipReason,
    [switch]$IncludeUntracked,
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Sincronizando cambios locales con GitHub (origin/$Branch)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

if ($SkipAudit -and [string]::IsNullOrWhiteSpace($SkipReason)) {
    Write-Host "`n[BLOQUEO DE SEGURIDAD] El uso de -SkipAudit requiere una justificacion con -SkipReason." -ForegroundColor Red
    Write-Host "Ejemplo: -SkipAudit -SkipReason 'Ajuste urgente de documentacion que no afecta al codigo.'" -ForegroundColor Yellow
    exit 1
}

# --- QUALITY GATE PREVIO A STAGING ---
if (-not $SkipAudit) {
    $juntaMedicaScript = Join-Path $PSScriptRoot "junta_medica.ps1"
    if (Test-Path $juntaMedicaScript) {
        Write-Host "`n>>> [GATE DE SEGURIDAD] Ejecutando junta medica forense antes de sincronizar..." -ForegroundColor Yellow
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $juntaMedicaScript -Fast
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n[BLOQUEO DE CALIDAD] Sincronizacion cancelada: La auditoria forense encontro fallas clinicas." -ForegroundColor Red
            Write-Host "Ejecute '.\release.ps1 -Fix' para sanear antes de comitear o use -SkipAudit si es justificado." -ForegroundColor Yellow
            exit 1
        }
        Write-Host " [OK] Quality Gate superado con exito (Auditoria limpia)." -ForegroundColor Green
    } else {
        Write-Host "`n[BLOQUEO DE SEGURIDAD] No se encontro 'junta_medica.ps1'. Cancelando para evitar staging a ciegas." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[PELIGRO] Se omitio el Quality Gate (-SkipAudit activo)." -ForegroundColor Magenta
    Write-Host "Justificacion registrada: '$SkipReason'" -ForegroundColor DarkYellow
}

# --- BARRERA CONTRA ARTEFACTOS FANTASMA Y TEMPORALES ---
$ghostPatterns = @("* (1).*", "* (2).*", "*.tmp", "*.bak", "*.orig", "*~", "*.swp")
$detectedGhosts = Get-ChildItem -Path $PSScriptRoot -Recurse -Include $ghostPatterns -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "[\\/]\.git[\\/]" }
if ($detectedGhosts.Count -gt 0) {
    Write-Host "`n[BLOQUEO DE CALIDAD] Se detectaron archivos fantasma o duplicados en el árbol de trabajo:" -ForegroundColor Red
    $detectedGhosts | ForEach-Object { Write-Host "  -> $($_.Name)" -ForegroundColor Red }
    Write-Host "Ejecute '.\release.ps1 -Fix' para purgarlos antes de sincronizar." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "`n>>> [1/3] Verificando estado del repositorio..." -ForegroundColor Yellow
    $status = git status --short
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host " [INFO] No hay cambios para sincronizar. El árbol de trabajo está limpio." -ForegroundColor Green
        exit 0
    }
    Write-Host "Cambios a ser sincronizados:"
    git status --short --branch

    # Detección de archivos no rastreados (Untracked)
    $untracked = git status --porcelain | Where-Object { $_ -match '^\?\?' }
    if ($untracked -and -not $IncludeUntracked) {
        Write-Host "`n[ADVERTENCIA] Se detectaron archivos sin rastrear (Untracked):" -ForegroundColor Yellow
        $untracked | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        Write-Host "Para proteger el repositorio de commits accidentales, se indexaran unicamente los archivos rastreados (git add -u)." -ForegroundColor Yellow
        Write-Host "Si desea incorporar nuevos archivos, agreguelos con git add especifico o use el parametro -IncludeUntracked." -ForegroundColor DarkYellow
    }

    Write-Host "`n>>> [2/3] Agregando cambios al staging area..." -ForegroundColor Yellow
    if ($IncludeUntracked) {
        Write-Host "  -> Indexando rastreados y nuevos (-IncludeUntracked activo)..." -ForegroundColor Yellow
        git add -A
    } else {
        Write-Host "  -> Indexando de forma segura solo archivos modificados/rastreados (git add -u)..." -ForegroundColor Green
        git add -u
    }

    Write-Host " [OK] Cambios agregados." -ForegroundColor Green

    Write-Host "`n>>> [3/3] Creando commit y enviando a remoto..." -ForegroundColor Yellow
    Write-Host "Mensaje: '$CommitMessage'" -ForegroundColor Gray
    git commit -m "$CommitMessage"
    Write-Host " [OK] Commit creado." -ForegroundColor Green

    Write-Host "Subiendo cambios a origin/$Branch (git push)..." -ForegroundColor Yellow
    & git push origin $Branch
    Write-Host " [OK] Push completado." -ForegroundColor Green

    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host " [OK] SINCRONIZACION COMPLETADA EXITOSAMENTE" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Cyan

}
catch {
    Write-Host "`n--- ERROR DURANTE LA SINCRONIZACION ---" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}