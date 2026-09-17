#Requires -Modules Microsoft.Data.Sqlite, Posh-RSJob

$ErrorActionPreference = "Stop"
$script:TotalTests = 0
$script:FailedTests = 0

# --- CONFIGURATION ---
$ApiBaseUrl = "http://localhost:5080"
$DbPath = Join-Path $PSScriptRoot "..\src\ADSOLUSOL.Presentation.Api\App_Data\campaigns.db"
$NodeId = "NODE_TEST_01"
# The private key is now read from an environment variable to avoid hardcoding secrets.
# The previous key is considered compromised and has been rotated.
$PrivateKeyHex = $env:ADSOLUSOL_TEST_NODE_PRIVATE_KEY
if ([string]::IsNullOrEmpty($PrivateKeyHex)) {
    Write-Error "FATAL: Private key not found. Please set the 'ADSOLUSOL_TEST_NODE_PRIVATE_KEY' environment variable."
    exit 1
}

# --- HELPER FUNCTIONS ---

function Write-TestHeader([string]$Title) {
    Write-Host "`n"
    Write-Host ("-" * 80)
    Write-Host "TEST: $Title"
    Write-Host ("-" * 80)
}

function Assert-Result {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$FailureMessage
    )
    $script:TotalTests++
    if ($Condition) {
        Write-Host "[PASS] - $TestName" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] - $TestName : $FailureMessage" -ForegroundColor Red
        $script:FailedTests++
    }
}

function Get-Signature {
    param(
        [string]$HttpMethod,
        [string]$RequestPath,
        [string]$QueryString,
        [string]$Timestamp,
        [string]$Nonce,
        [string]$Body
    )
    $canonicalMessage = "SOLUSOL_AUTH_V1|$HttpMethod|$RequestPath|$QueryString|$NodeId|$Timestamp|$Nonce|$Body"
    $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($canonicalMessage)
    
    $privateKeyBytes = [System.Convert]::FromHexString($PrivateKeyHex)
    $algorithm = [NSec.Cryptography.SignatureAlgorithm]::Ed25519
    $key = [NSec.Cryptography.Key]::Import($algorithm, $privateKeyBytes, [NSec.Cryptography.KeyBlobFormat]::RawPrivateKey)
    
    $signatureBytes = $algorithm.Sign($key, $messageBytes)
    return [System.Convert]::ToBase64String($signatureBytes)
}

function Invoke-ApiRequest {
    param(
        [string]$Path,
        [string]$Query,
        [string]$Body = '""',
        [string]$Timestamp = ([System.DateTime]::UtcNow.ToString("o")),
        [string]$Nonce = ([System.Guid]::NewGuid().ToString())
    )
    
    $signature = Get-Signature -HttpMethod "POST" -RequestPath $Path -QueryString $Query -Timestamp $Timestamp -Nonce $Nonce -Body $Body
    
    $headers = @{
        "X-Solusol-Node-Id"     = $NodeId
        "X-Solusol-Timestamp"   = $Timestamp
        "X-Solusol-Nonce"       = $Nonce
        "X-Solusol-Signature"   = $signature
        "Content-Type"          = "application/json"
    }

    $uri = "$ApiBaseUrl$Path$Query"
    Write-Host "EXECUTING: POST $uri"
    Write-Host "HEADERS:"
    $headers.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }
    
    try {
        return Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $Body -UseBasicParsing
    } catch {
        return $_.Exception.Response
    }
}

function Query-Db([string]$Query) {
    $connection = New-Object Microsoft.Data.Sqlite.SqliteConnection("Data Source=$DbPath")
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $Query
    $result = $command.ExecuteScalar()
    $connection.Close()
    return $result
}

# --- TEST EXECUTION ---

Add-Type -Path (Join-Path $PSScriptRoot "..\src\ADSOLUSOL.Presentation.Api\bin\Debug\net8.0\NSec.Cryptography.dll")

Write-Host "================================================================================"
Write-Host " ADSOLUSOL - FINAL RUNTIME VERIFICATION SCRIPT"
Write-Host "================================================================================"
Write-Host "API Base: $ApiBaseUrl"
Write-Host "DB Path: $DbPath"
Write-Host "UTC Now: $([System.DateTime]::UtcNow.ToString("o"))"

# --- DB SAFETY CHECK ---
if ($DbPath -notlike "*\App_Data\campaigns.db" -or $DbPath -like "*production*" -or $DbPath -like "*staging*") {
    Write-Error "SAFETY ABORT: Script is configured to run against a non-standard or potentially production DB path: $DbPath"
    Write-Error "This script performs destructive operations (DELETE) and will only run against the default development DB."
    exit 1
}
Write-Host "`nDB Safety Check: PASSED. Target is the expected development database." -ForegroundColor Green


# 1. EXACT REPLAY TEST
Write-TestHeader "1. Exact Replay (Anti-Replay at Transport Layer)"
$timestamp1 = ([System.DateTime]::UtcNow.ToString("o"))
$nonce1 = "final-test-nonce-replay-01"
$eventId1 = "final-test-event-replay-01"
$query1 = "?event_id=$eventId1&placement_id=p-main"
$path1 = "/api/marketing/adsolusol/campaigns/campaign-01/click"

Query-Db "DELETE FROM ad_events WHERE event_id = '$eventId1'" | Out-Null
$dbBefore1 = Query-Db "SELECT COUNT(*) FROM ad_events WHERE event_id = '$eventId1'"

Write-Host "`n--- 1.1: Initial Valid Request ---"
$response1 = Invoke-ApiRequest -Path $path1 -Query $query1 -Timestamp $timestamp1 -Nonce $nonce1
$dbAfter1 = Query-Db "SELECT COUNT(*) FROM ad_events WHERE event_id = '$eventId1'"
Assert-Result "Initial request status is 202" ($response1.StatusCode -eq 202) "Actual: $($response1.StatusCode)"
Assert-Result "DB count is 1 after initial request" ($dbAfter1 -eq 1) "Actual: $dbAfter1"

Write-Host "`n--- 1.2: Exact Replay Request ---"
$response2 = Invoke-ApiRequest -Path $path1 -Query $query1 -Timestamp $timestamp1 -Nonce $nonce1
$dbAfter2 = Query-Db "SELECT COUNT(*) FROM ad_events WHERE event_id = '$eventId1'"
Assert-Result "Replay request status is 401" ($response2.StatusCode -eq 401) "Actual: $($response2.StatusCode)"
Assert-Result "DB count remains 1 after replay" ($dbAfter2 -eq 1) "Actual: $dbAfter2"

# 2. BUSINESS IDEMPOTENCY TEST
Write-TestHeader "2. Business Idempotency (New Nonce, Same Event)"
$eventId2 = "final-test-event-idempotency-01"
$query2 = "?event_id=$eventId2&placement_id=p-main"
$path2 = "/api/marketing/adsolusol/campaigns/campaign-01/click"

Query-Db "DELETE FROM ad_events WHERE event_id = '$eventId2'" | Out-Null

Write-Host "`n--- 2.1: First Business Event ---"
$response3 = Invoke-ApiRequest -Path $path2 -Query $query2
Assert-Result "First business event status is 202" ($response3.StatusCode -eq 202) "Actual: $($response3.StatusCode)"

Write-Host "`n--- 2.2: Second Business Event (Duplicate) ---"
$response4 = Invoke-ApiRequest -Path $path2 -Query $query2
$content4 = $response4.Content | ConvertFrom-Json
Assert-Result "Second business event status is 200" ($response4.StatusCode -eq 200) "Actual: $($response4.StatusCode)"
Assert-Result "Second business event response is DUPLICATE" ($content4.status -eq "DUPLICATE") "Actual: $($content4.status)"
$dbAfter4 = Query-Db "SELECT COUNT(*) FROM ad_events WHERE event_id = '$eventId2'"
Assert-Result "DB count is 1 after duplicate business event" ($dbAfter4 -eq 1) "Actual: $dbAfter4"

# 3. TIMESTAMP WINDOW TEST
Write-TestHeader "3. Timestamp Window"
$path3 = "/api/marketing/adsolusol/campaigns/campaign-01/toggle"

Write-Host "`n--- 3.1: Expired Timestamp (-10 minutes) ---"
$ts_expired = ([System.DateTime]::UtcNow.AddMinutes(-10).ToString("o"))
$resp_expired = Invoke-ApiRequest -Path $path3 -Query "" -Timestamp $ts_expired
Assert-Result "Expired timestamp is rejected with 401" ($resp_expired.StatusCode -eq 401) "Actual: $($resp_expired.StatusCode)"

Write-Host "`n--- 3.2: Future Timestamp (+10 minutes) ---"
$ts_future = ([System.DateTime]::UtcNow.AddMinutes(10).ToString("o"))
$resp_future = Invoke-ApiRequest -Path $path3 -Query "" -Timestamp $ts_future
Assert-Result "Future timestamp is rejected with 401" ($resp_future.StatusCode -eq 401) "Actual: $($resp_future.StatusCode)"

# 4. PLACEMENT_ID CONTRACT TEST
Write-TestHeader "4. Placement ID Contract"
$eventId4 = "final-test-event-pid-01"
$path4 = "/api/marketing/adsolusol/campaigns/campaign-01/click"

Write-Host "`n--- 4.1: Request without placement_id ---"
$query_nopid = "?event_id=$eventId4"
$resp_nopid = Invoke-ApiRequest -Path $path4 -Query $query_nopid
Assert-Result "Request without placement_id is rejected with 400" ($resp_nopid.StatusCode -eq 400) "Actual: $($resp_nopid.StatusCode)"

Write-Host "`n--- 4.2: Request with placement_id ---"
$query_pid = "?event_id=$eventId4&placement_id=p-footer"
$resp_pid = Invoke-ApiRequest -Path $path4 -Query $query_pid
Assert-Result "Request with placement_id is accepted with 202" ($resp_pid.StatusCode -eq 202) "Actual: $($resp_pid.StatusCode)"

# 5. CONCURRENT REPLAY TEST
Write-TestHeader "5. Concurrent Replay"
$timestamp5 = ([System.DateTime]::UtcNow.ToString("o"))
$nonce5 = "final-test-nonce-concurrent-01"
$eventId5 = "final-test-event-concurrent-01"
$query5 = "?event_id=$eventId5&placement_id=p-side"
$path5 = "/api/marketing/adsolusol/campaigns/campaign-01/click"

Query-Db "DELETE FROM ad_events WHERE event_id = '$eventId5'" | Out-Null

$signature5 = Get-Signature -HttpMethod "POST" -RequestPath $path5 -QueryString $query5 -Timestamp $timestamp5 -Nonce $nonce5 -Body '""'
$headers5 = @{
    "X-Solusol-Node-Id"     = $NodeId
    "X-Solusol-Timestamp"   = $timestamp5
    "X-Solusol-Nonce"       = $nonce5
    "X-Solusol-Signature"   = $signature5
    "Content-Type"          = "application/json"
}
$uri5 = "$ApiBaseUrl$path5$query5"

$scriptBlock = {
    param($uri, $headers)
    try {
        return Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body '""' -UseBasicParsing
    } catch {
        return $_.Exception.Response
    }
}

Write-Host "Launching 2 identical concurrent requests..."
$job1 = Start-RSJob -ScriptBlock $scriptBlock -ArgumentList $uri5, $headers5
$job2 = Start-RSJob -ScriptBlock $scriptBlock -ArgumentList $uri5, $headers5

$concurrent_responses = Wait-RSJob -Job $job1, $job2 | Receive-RSJob

$acceptedCount = ($concurrent_responses | Where-Object { $_.StatusCode -eq 202 }).Count
$rejectedCount = ($concurrent_responses | Where-Object { $_.StatusCode -eq 401 }).Count

Write-Host "Concurrent responses received:"
foreach($r in $concurrent_responses) {
    Write-Host "  - StatusCode: $($r.StatusCode)"
}

Assert-Result "Exactly one concurrent request was accepted (202)" ($acceptedCount -eq 1) "Actual: $acceptedCount"
Assert-Result "Exactly one concurrent request was rejected (401)" ($rejectedCount -eq 1) "Actual: $rejectedCount"
$dbAfter5 = Query-Db "SELECT COUNT(*) FROM ad_events WHERE event_id = '$eventId5'"
Assert-Result "DB count is 1 after concurrent requests" ($dbAfter5 -eq 1) "Actual: $dbAfter5"

# 6. QUERY TAMPERING TEST
Write-TestHeader "6. Query Tampering (Signature Mismatch)"
$eventIdA = "tamper-test-event-A"
$placementX = "p-tamper-X"
$path6 = "/api/marketing/adsolusol/campaigns/campaign-01/click"

# 6.1: Sign for Event A, but send for Event B
Write-Host "`n--- 6.1: Tampering with event_id ---"
$originalQuery = "?event_id=$eventIdA&placement_id=$placementX"
$tamperedQuery = "?event_id=tamper-test-event-B&placement_id=$placementX"

$timestamp6_1 = ([System.DateTime]::UtcNow.ToString("o"))
$nonce6_1 = ([System.Guid]::NewGuid().ToString())

# Generate signature for the ORIGINAL query
$signature6_1 = Get-Signature -HttpMethod "POST" -RequestPath $path6 -QueryString $originalQuery -Timestamp $timestamp6_1 -Nonce $nonce6_1 -Body '""'

# Now, use this signature to make a request with the TAMPERED query
$headers6_1 = @{
    "X-Solusol-Node-Id"     = $NodeId
    "X-Solusol-Timestamp"   = $timestamp6_1
    "X-Solusol-Nonce"       = $nonce6_1
    "X-Solusol-Signature"   = $signature6_1
    "Content-Type"          = "application/json"
}
$uri6_1 = "$ApiBaseUrl$path6$tamperedQuery"
Write-Host "EXECUTING TAMPERED REQUEST: POST $uri6_1"
Write-Host "HEADERS (with signature for event_id=A):"
$headers6_1.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }

try { $resp_tamper1 = Invoke-WebRequest -Uri $uri6_1 -Method Post -Headers $headers6_1 -Body '""' -UseBasicParsing } catch { $resp_tamper1 = $_.Exception.Response }
Assert-Result "Tampered event_id request is rejected with 401" ($resp_tamper1.StatusCode -eq 401) "Actual: $($resp_tamper1.StatusCode)"

# 6.2: Sign for Placement X, but send for Placement Y
Write-Host "`n--- 6.2: Tampering with placement_id ---"
$originalQuery2 = "?event_id=$eventIdA&placement_id=$placementX"
$tamperedQuery2 = "?event_id=$eventIdA&placement_id=p-tamper-Y"

$timestamp6_2 = ([System.DateTime]::UtcNow.ToString("o"))
$nonce6_2 = ([System.Guid]::NewGuid().ToString())

# Generate signature for the ORIGINAL query
$signature6_2 = Get-Signature -HttpMethod "POST" -RequestPath $path6 -QueryString $originalQuery2 -Timestamp $timestamp6_2 -Nonce $nonce6_2 -Body '""'

# Use signature for a request with the TAMPERED query
$headers6_2 = @{
    "X-Solusol-Node-Id"     = $NodeId
    "X-Solusol-Timestamp"   = $timestamp6_2
    "X-Solusol-Nonce"       = $nonce6_2
    "X-Solusol-Signature"   = $signature6_2
    "Content-Type"          = "application/json"
}
$uri6_2 = "$ApiBaseUrl$path6$tamperedQuery2"
Write-Host "EXECUTING TAMPERED REQUEST: POST $uri6_2"
Write-Host "HEADERS (with signature for placement_id=X):"
$headers6_2.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }

try { $resp_tamper2 = Invoke-WebRequest -Uri $uri6_2 -Method Post -Headers $headers6_2 -Body '""' -UseBasicParsing } catch { $resp_tamper2 = $_.Exception.Response }
Assert-Result "Tampered placement_id request is rejected with 401" ($resp_tamper2.StatusCode -eq 401) "Actual: $($resp_tamper2.StatusCode)"

# --- FINAL SUMMARY ---
Write-Host "`n"
Write-Host ("=" * 80)
Write-Host "VERIFICATION SUMMARY"
Write-Host ("=" * 80)
Write-Host "Total Checks: $script:TotalTests"
Write-Host "Failed Checks: $script:FailedTests" -ForegroundColor $(if ($script:FailedTests -gt 0) { "Red" } else { "Green" })

if ($script:FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
