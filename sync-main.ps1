[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="El mensaje para el commit es obligatorio.")]
    [string]$CommitMessage,

    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Sincronizando cambios locales con GitHub (origin/$Branch)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

try {
    Write-Host "`n>>> [1/4] Verificando estado del repositorio..." -ForegroundColor Yellow
    $status = git status --short
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host " [INFO] No hay cambios para sincronizar. El árbol de trabajo está limpio." -ForegroundColor Green
        exit 0
    }
    Write-Host "Cambios a ser sincronizados:"
    git status --short

    Write-Host "`n>>> [2/4] Agregando todos los cambios al staging area (git add .)..." -ForegroundColor Yellow
    git add .
    Write-Host " [OK] Cambios agregados." -ForegroundColor Green

    Write-Host "`n>>> [3/4] Creando commit..." -ForegroundColor Yellow
    Write-Host "Mensaje: '$CommitMessage'" -ForegroundColor Gray
    git commit -m $CommitMessage
    Write-Host " [OK] Commit creado." -ForegroundColor Green

    Write-Host "`n>>> [4/4] Subiendo cambios a origin/$Branch (git push)..." -ForegroundColor Yellow
    git push origin $Branch
    Write-Host " [OK] Push completado." -ForegroundColor Green

    Write-Host "`n======================================================================" -ForegroundColor Cyan
    Write-Host " ✅ SINCRONIZACIÓN COMPLETADA EXITOSAMENTE" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Cyan

} catch {
    Write-Host "`n--- ERROR DURANTE LA SINCRONIZACIÓN ---" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}