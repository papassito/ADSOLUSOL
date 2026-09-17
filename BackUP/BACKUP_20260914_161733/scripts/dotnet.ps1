param([Parameter(ValueFromRemainingArguments = $true)][string[]]$ToolArguments)
$ErrorActionPreference = 'Stop'
$sdkPath = $env:ADSOLUSOL_DOTNET
if (-not $sdkPath) {
    $portable = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Codex\tools\dotnet\dotnet.exe'
    if (Test-Path -LiteralPath $portable) { $sdkPath = $portable }
    else { $sdkPath = (Get-Command dotnet -ErrorAction Stop).Source }
}
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
& $sdkPath @ToolArguments
exit $LASTEXITCODE
