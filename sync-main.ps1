[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$CommitMessage = "",
    [switch]$SkipAudit,
    [string]$SkipReason = "",
    [string]$Branch = ""
)

$ErrorActionPreference = "Stop"

$targetScript = Join-Path $PSScriptRoot "update_github.ps1"
if (-not (Test-Path $targetScript)) {
    Write-Host "[ERROR] No se encontró el script estándar update_github.ps1 en $targetScript" -ForegroundColor Red
    exit 1
}

$params = @{}
if (-not [string]::IsNullOrWhiteSpace($CommitMessage)) {
    $params["Message"] = $CommitMessage
}
if (-not [string]::IsNullOrWhiteSpace($Branch)) {
    $params["Branch"] = $Branch
}
if ($SkipAudit) {
    $params["SkipAudit"] = $true
    $params["SkipReason"] = $SkipReason
}

& $targetScript @params