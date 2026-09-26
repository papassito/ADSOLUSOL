[CmdletBinding()]
param(
    [string]$Message = "chore: sync repository updates $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ">>> Agregando todos los cambios y enviando a origin/$Branch..." -ForegroundColor Cyan
git add -A
git commit -m "$Message"
git push origin $Branch
Write-Host ">>> Sincronizacion completada con exito." -ForegroundColor Green