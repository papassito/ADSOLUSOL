# cleanup-project.ps1
# This script removes obsolete, duplicated, and artifact files
# from the ADSOLUSOL repository to clean up the project.

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Remove-ObsoleteFile {
    param(
        [string]$RelativePath,
        [string]$Reason
    )
    $fullPath = Join-Path $Root $RelativePath
    if (Test-Path $fullPath) {
        Write-Host "Removing: $RelativePath`n  Reason: $Reason" -ForegroundColor Yellow
        Remove-Item -Path $fullPath -Force
        Write-Host "  [OK] Removed." -ForegroundColor Green
    } else {
        Write-Host "Skipping: $RelativePath (not found)." -ForegroundColor Gray
    }
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      STARTING ADSOLUSOL PROJECT CLEANUP     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. Misplaced Project Files ---
Write-Host "--- Cleaning up misplaced project (.csproj) files..." -f Magenta
Remove-ObsoleteFile `
    -RelativePath "src\ADSOLUSOL.Presentation.Api\ADSOLUSOL.Presentation.Desktop.csproj" `
    -Reason "Empty and corrupt project file in the API folder."

# --- 2. Duplicate or Misplaced Code Files ---
Write-Host "`n--- Cleaning up duplicate or misplaced code (.cs) files..." -f Magenta
Remove-ObsoleteFile `
    -RelativePath "NodeRegistry.cs" `
    -Reason "Duplicate copy of a class that already exists in the Infrastructure project."
Remove-ObsoleteFile `
    -RelativePath "MauiProgram.cs" `
    -Reason "Stray MAUI startup file in the root. The correct one is in Presentation.Desktop."
Remove-ObsoleteFile `
    -RelativePath "src\ADSOLUSOL.Infrastructure\MauiProgram.cs" `
    -Reason "Empty and misplaced MAUI startup file in Infrastructure."
Remove-ObsoleteFile `
    -RelativePath "src\ADSOLUSOL.Domain\Interfaces\NODEREGISTRY.CS" `
    -Reason "Empty file left over from a refactoring."

# --- 3. Obsolete UI Artifacts in the API Project ---
Write-Host "`n--- Cleaning up obsolete UI artifacts (.xaml, .razor) from the API project..." -f Magenta
Remove-ObsoleteFile -RelativePath "src\ADSOLUSOL.Presentation.Api\App.xaml" -Reason "Obsolete UI artifact."
Remove-ObsoleteFile -RelativePath "src\ADSOLUSOL.Presentation.Api\MainPage.xaml" -Reason "Obsolete UI artifact."
Remove-ObsoleteFile -RelativePath "src\ADSOLUSOL.Presentation.Api\Routes.razor" -Reason "Obsolete UI artifact."
Remove-ObsoleteFile -RelativePath "src\ADSOLUSOL.Presentation.Api\_Imports.razor" -Reason "Obsolete UI artifact."

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      CLEANUP COMPLETE     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan