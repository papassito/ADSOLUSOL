[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Message = "",

    [string]$Branch = "",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

try { $null = chcp 65001 } catch {}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor DarkCyan
}

function Limpiar-BasuraGit {

    Write-Host ">> Higiene pre-commit..." -ForegroundColor Yellow

    $junkPatterns = @(
        "*.tmp",
        "*.bak",
        "*.orig",
        "*~",
        "*.swp",
        "*.log",
        "Thumbs.db",
        "desktop.ini",
        ".DS_Store",
        "*_old.*",
        "*_copy.*"
    )

    $deleted = 0

    Get-ChildItem -Path . -Recurse -Include $junkPatterns -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]'
        } |
        ForEach-Object {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            $deleted++
        }

    if ($deleted -gt 0) {
        Write-Host "[OK] $deleted archivo(s) temporal(es) eliminado(s)." -ForegroundColor Green
    }
}

function Generar-MensajeCommit {
    param([string[]]$Files)

    if (-not $Files -or $Files.Count -eq 0) {
        return "chore: repository synchronization"
    }

    return "chore: repository update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

if ([string]::IsNullOrWhiteSpace($Branch)) {

    $Branch = (git branch --show-current).Trim()

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        $Branch = "main"
    }
}

Show-Section "PUSH PIPELINE"

Limpiar-BasuraGit

git add -A

$staged = @(git diff --cached --name-status)

if ($staged.Count -eq 0) {

    Write-Host ""
    Write-Host "[OK] No existen cambios pendientes." -ForegroundColor Yellow
    exit 0
}

Show-Section "ARCHIVOS A CONFIRMAR"

$staged | ForEach-Object {
    Write-Host $_ -ForegroundColor White
}

Write-Host ""
git diff --cached --stat

if ([string]::IsNullOrWhiteSpace($Message)) {

    $Message = Generar-MensajeCommit $staged
}

Write-Host ""
Write-Host "Commit:" -ForegroundColor Cyan
Write-Host $Message -ForegroundColor White

Write-Host ""
Write-Host "Branch:" -ForegroundColor Cyan
Write-Host $Branch -ForegroundColor White

Show-Section "COMMIT"

git commit -m "$Message"

Show-Section "PUSH"

git push origin $Branch

Write-Host ""
Write-Host "[OK] Sincronización completada correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "Siguiente paso:" -ForegroundColor Cyan
Write-Host "Plesk -> Pull ahora -> Desplegar ahora" -ForegroundColor Yellow