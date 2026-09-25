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

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Sincronizando cambios locales con GitHub (origin/$Branch)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

if ($SkipAudit -and [string]::IsNullOrWhiteSpace($SkipReason)) {
    Write-Host "`n[BLOQUEO DE SEGURIDAD] El uso de -SkipAudit requiere una justificación con -SkipReason." -ForegroundColor Red
    Write-Host "Ejemplo: -SkipAudit -SkipReason 'Ajuste urgente de documentación que no afecta al código.'" -ForegroundColor Yellow
    exit 1
}

# --- QUALITY GATE PREVIO A STAGING ---
if (-not $SkipAudit) {
    $juntaMedicaScript = Join-Path $PSScriptRoot "junta_medica.ps1"
    if (Test-Path $juntaMedicaScript) {
        Write-Host "`n>>> [GATE DE SEGURIDAD] Ejecutando junta médica forense antes de sincronizar..." -ForegroundColor Yellow
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $juntaMedicaScript -Fast
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n[BLOQUEO DE CALIDAD] Sincronización cancelada: La auditoría forense encontró fallas clínicas." -ForegroundColor Red
            Write-Host "Ejecute '.\release.ps1 -Fix' para sanear antes de comitear o use -SkipAudit si es justificado." -ForegroundColor Yellow
            exit 1
        }
        Write-Host " [OK] Quality Gate superado con éxito (Auditoría limpia)." -ForegroundColor Green
    } else {
        Write-Host "`n[BLOQUEO DE SEGURIDAD] No se encontró 'junta_medica.ps1'. Cancelando para evitar staging a ciegas." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "`n[PELIGRO] Se omitió el Quality Gate (-SkipAudit activo)." -ForegroundColor Magenta
    Write-Host "Justificación registrada: '$SkipReason'" -ForegroundColor DarkYellow
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
        Write-Host "Para proteger el repositorio de commits accidentales, se indexarán únicamente los archivos rastreados (git add -u)." -ForegroundColor Yellow
        Write-Host "Si desea incorporar nuevos archivos, agréguelos con git add específico o use el parámetro -IncludeUntracked." -ForegroundColor DarkYellow
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
    Write-Host "`n--- ERROR DURANTE LA SINCRONIZACIÓN ---" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}