$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
$ApiBaseUrl = "http://localhost:5080"
$DbPath = Join-Path $PSScriptRoot "..\src\ADSOLUSOL.Presentation.Api\App_Data\campaigns.db"

function Write-Step([string]$Title) {
    Write-Host "`n"
    Write-Host ("-" * 80)
    Write-Host "E2E STEP: $Title"
    Write-Host ("-" * 80)
}

function Invoke-ApiPost {
    param([string]$Path, [object]$Body)
    $jsonBody = $Body | ConvertTo-Json
    Write-Host "POST $ApiBaseUrl$Path"
    Write-Host "BODY: $jsonBody"
    return Invoke-RestMethod -Uri "$ApiBaseUrl$Path" -Method Post -Body $jsonBody -ContentType "application/json"
}

function Invoke-ApiGet {
    param([string]$Path)
    Write-Host "GET $ApiBaseUrl$Path"
    return Invoke-RestMethod -Uri "$ApiBaseUrl$Path" -Method Get
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

Write-Host "================================================================================"
Write-Host " ADSOLUSOL - END-TO-END (E2E) FLOW TEST"
Write-Host "================================================================================"

# 1. Create Campaign
Write-Step "1. Create Campaign"
$campaignId = "e2e-campaign-$(Get-Random)"
$campaignBody = @{
    Id = $campaignId
    Name = "E2E Test Campaign"
    Status = "SCHEDULED"
    Budget = 100.0
    CostPerMille = 2.0 # $2 CPM
    CostPerClick = 0.5  # $0.50 CPC
}
Invoke-ApiPost -Path "/api/campaigns" -Body $campaignBody

# 2. Create Placement
Write-Step "2. Create Placement"
$placementCode = "e2e-placement-main"
$placementBody = @{
    PlacementCode = $placementCode
    Name = "E2E Main Placement"
    IsEnabled = $true
}
$placement = Invoke-ApiPost -Path "/api/placements" -Body $placementBody
$placementId = $placement.id

# 3. Create Creative
Write-Step "3. Create Creative"
$creativeBody = @{
    Name = "E2E Test Creative"
    ContentUrl = "http://example.com/ad.png"
    TargetUrl = "http://example.com/landing"
    IsEnabled = $true
}
$creative = Invoke-ApiPost -Path "/api/creatives" -Body $creativeBody
$creativeId = $creative.id

# 4. Associate entities
Write-Step "4. Associate Campaign, Placement, and Creative"
Invoke-ApiPost -Path "/api/assignments/placement" -Body @{ CampaignId = $campaignId; EntityId = $placementId }
Invoke-ApiPost -Path "/api/assignments/creative" -Body @{ CampaignId = $campaignId; EntityId = $creativeId }

# 5. Activate Campaign
Write-Step "5. Activate Campaign"
Invoke-ApiPost -Path "/api/campaigns/$campaignId/status" -Body @{ Status = "ACTIVE" }

# 6. Request Ad
Write-Step "6. Request Ad from Serving Engine"
$adDecision = Invoke-ApiGet -Path "/api/serve?placementId=$placementCode"
if ($adDecision.creativeId -ne $creativeId) { throw "Did not receive the expected creative." }
Write-Host "SUCCESS: Received correct creative." -ForegroundColor Green

# 7. Register Impression
Write-Step "7. Register Impression"
$impressionEventId = "e2e-impression-$(Get-Random)"
$impressionBody = @{ EventId = $impressionEventId; CreativeId = $creativeId; PlacementCode = $placementCode }
Invoke-ApiPost -Path "/api/campaigns/$campaignId/impression" -Body $impressionBody

# 8. Register Click
Write-Step "8. Register Click"
$clickEventId = "e2e-click-$(Get-Random)"
$clickBody = @{ EventId = $clickEventId; CreativeId = $creativeId; PlacementCode = $placementCode }
Invoke-ApiPost -Path "/api/campaigns/$campaignId/click" -Body $clickBody

# 9. Test Idempotency
Write-Step "9. Test Idempotency (repeat click)"
$duplicateResult = Invoke-ApiPost -Path "/api/campaigns/$campaignId/click" -Body $clickBody
if ($duplicateResult.status -ne "DUPLICATE") { throw "Idempotency test failed." }
Write-Host "SUCCESS: Idempotency check passed." -ForegroundColor Green

# 10. Consult Metrics
Write-Step "10. Consult Metrics"
$metrics = Invoke-ApiGet -Path "/api/campaigns/$campaignId/metrics"
if ($metrics.impressions -ne 1) { throw "Impressions count is wrong." }
if ($metrics.clicks -ne 1) { throw "Clicks count is wrong." }
if ($metrics.ctr -ne 100.0) { throw "CTR calculation is wrong." }

$expectedSpend = (2.0 / 1000) + 0.5 # CPM cost + CPC cost
if ($metrics.budgetSpent -ne $expectedSpend) { throw "Budget spend calculation is wrong. Expected $expectedSpend, got $($metrics.budgetSpent)" }
Write-Host "SUCCESS: Metrics are correct." -ForegroundColor Green

# 11. Check SQLite
Write-Step "11. Final check on SQLite Database"
$dbCampaignBudget = Query-Db "SELECT Budget FROM Campaigns WHERE Id = '$campaignId'"
$dbCampaignSpend = Query-Db "SELECT BudgetSpent FROM Campaigns WHERE Id = '$campaignId'"
$dbEvents = Query-Db "SELECT COUNT(*) FROM AdEvents WHERE CampaignId = '$campaignId'"
if ($dbEvents -ne 2) { throw "DB event count is wrong." }
if (100 - $dbCampaignBudget -ne $expectedSpend) { throw "DB budget calculation is wrong." }
Write-Host "SUCCESS: Database state is correct." -ForegroundColor Green

Write-Host "`n`nE2E FLOW TEST PASSED SUCCESSFULLY!" -ForegroundColor Green