[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    $RemainingArgs
)

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

& (Join-Path $PSScriptRoot "scripts\audit_ultra-mitotero.ps1") @RemainingArgs