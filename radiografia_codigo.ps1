[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    $RemainingArgs
)

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

& (Join-Path $PSScriptRoot "scripts\radiografia_codigo.ps1") @RemainingArgs