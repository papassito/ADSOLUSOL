param([string]$DotnetPath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = if ($scriptDir) { Split-Path -Parent $scriptDir } else { $pwd.Path }
if (-not $DotnetPath) {
    $DotnetPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Codex\tools\dotnet\dotnet.exe'
    if (-not (Test-Path -LiteralPath $DotnetPath)) { $DotnetPath = (Get-Command dotnet -ErrorAction Stop).Source }
}
$dll = Join-Path $root 'src\ADSOLUSOL.Presentation.Api\bin\Debug\net8.0\ADSOLUSOL.Presentation.Api.dll'
if (-not (Test-Path -LiteralPath $dll)) { throw 'Build the solution first.' }
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$scratch = Join-Path $tempRoot ('adsolusol-http-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
$listener.Start()
$port = $listener.LocalEndpoint.Port
$listener.Stop()
$base = "http://127.0.0.1:$port"
$key = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
$client = [Net.Http.HttpClient]::new()
$client.DefaultRequestHeaders.Add('X-Api-Key', $key)
$process = $null
function StartApi {
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $DotnetPath
    $info.Arguments = '"' + $dll + '"'
    $info.WorkingDirectory = $scratch
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.EnvironmentVariables['ASPNETCORE_URLS'] = $base
    $info.EnvironmentVariables['Api__Key'] = $key
    $info.EnvironmentVariables['Api__TenantId'] = 'http-test'
    $info.EnvironmentVariables['Storage__Path'] = (Join-Path $scratch 'campaigns.db')
    $dotnetDir = Split-Path -Parent $DotnetPath
    $info.EnvironmentVariables['DOTNET_ROOT'] = $dotnetDir
    $p = [Diagnostics.Process]::Start($info)
    # Drain logs asynchronously to prevent blocked pipes. No secrets are logged.
    $script:stdout = $p.StandardOutput.ReadToEndAsync()
    $script:stderr = $p.StandardError.ReadToEndAsync()
    for ($attempt = 0; $attempt -lt 80; $attempt++) {
        if ($p.HasExited) { 
            $errText = if ($script:stderr.IsCompleted) { $script:stderr.Result } else { $p.StandardError.ReadToEnd() }
            throw "API exited: $errText" 
        }
        try {
            $response = $client.GetAsync("$base/api/health/storage").GetAwaiter().GetResult()
            $ready = [int]$response.StatusCode -eq 200
            $response.Dispose()
            if ($ready) { return $p }
        } catch { }
        Start-Sleep -Milliseconds 100
    }
    if (-not $p.HasExited) { $p.Kill(); $p.WaitForExit() }
    throw 'API did not become ready.'
}
function Request([string]$method, [string]$path, [string]$body, [int]$expected) {
    Write-Host "Checking $method $path"
    $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::new($method), "$base$path")
    if ($body) { $request.Content = [Net.Http.StringContent]::new($body, [Text.Encoding]::UTF8, 'application/json') }
    try {
        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        try {
            $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            if ([int]$response.StatusCode -ne $expected) { throw "$method $path expected $expected, got $([int]$response.StatusCode): $text" }
            if ($text) { return ($text | ConvertFrom-Json) }
        } finally { $response.Dispose() }
    } finally { $request.Dispose() }
}
try {
    $process = StartApi
    $health = Request GET '/api/health' '' 503
    if ($health.dependencies.persistence -ne 'AVAILABLE' -or $health.dependencies.marketingBrain -ne 'UNAVAILABLE') { throw 'Health dependencies mismatch.' }
    $client.DefaultRequestHeaders.Remove('X-Api-Key') | Out-Null
    Request GET '/api/Campaign' '' 401 | Out-Null
    $client.DefaultRequestHeaders.Add('X-Api-Key', $key)
    Request POST '/api/Campaign' '{"name":"","budget":1}' 400 | Out-Null
    Request POST '/api/Campaign' '{"name":"Bad budget","budget":-1}' 400 | Out-Null
    $campaign = Request POST '/api/marketing/adsolusol/campaigns' '{"name":"Persistence test","budget":123.45}' 201
    if ($campaign.status -ne 'SCHEDULED' -or $campaign.tenantId -ne 'http-test') { throw 'Incorrect campaign defaults.' }
    Request POST "/api/Campaign/$($campaign.id)/content" '' 503 | Out-Null
    $process.Kill(); $process.WaitForExit(); $process.Dispose(); $process = $null
    $process = StartApi
    $recovered = Request GET "/api/Campaign/$($campaign.id)" '' 200
    if ($recovered.name -ne $campaign.name -or $recovered.budget -ne $campaign.budget) { throw 'Data did not survive API restart.' }
    Request GET ('/api/Campaign/' + [guid]::NewGuid()) '' 404 | Out-Null
    Write-Output 'PASS: HTTP authentication, validation, storage health, missing SIC, and persistence after restart.'
} catch {
    if ($process -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
    if ($script:stdout -and $script:stdout.IsCompleted) { Write-Output $script:stdout.Result }
    if ($script:stderr -and $script:stderr.IsCompleted) { Write-Output $script:stderr.Result }
    Write-Output $_.Exception.ToString()
    throw
} finally {
    if ($process) { if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit() }; $process.Dispose() }
    $client.Dispose()
    $resolved = [IO.Path]::GetFullPath($scratch)
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notmatch '^adsolusol-http-[a-f0-9]{32}$') { throw 'Unsafe cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
