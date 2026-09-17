$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = if ($scriptDir) { Split-Path -Parent $scriptDir } else { $pwd.Path }
$files = @(Get-ChildItem -LiteralPath $root -Recurse -Force -File | Where-Object { $_.FullName -notmatch '\\(\.git|bin|obj|\.vs|TestResults|coverage)\\' })
$errorsFound = @()
$solutions = @($files | Where-Object { $_.Extension -eq '.sln' -or $_.Extension -eq '.slnx' })
if ($solutions.Count -ne 1 -or $solutions[0].FullName -ne (Join-Path $root 'ADSOLUSOL.sln')) { $errorsFound += 'Expected one root ADSOLUSOL.sln.' }
$sln = Get-Content -LiteralPath (Join-Path $root 'ADSOLUSOL.sln') -Raw
$projects = @($files | Where-Object { $_.Extension -eq '.csproj' })
$registered = @([regex]::Matches($sln, 'Project\("[^"\r\n]+"\) = "[^"\r\n]+", "([^"\r\n]+\.csproj)"'))
if ($registered.Count -ne $projects.Count) { $errorsFound += 'Solution project count differs from source project count.' }
foreach ($entry in $registered) { if (-not (Test-Path -LiteralPath (Join-Path $root $entry.Groups[1].Value))) { $errorsFound += "Missing solution project: $($entry.Groups[1].Value)" } }
foreach ($project in $projects) {
    $relative = $project.FullName.Substring($root.Length + 1)
    if (-not $sln.Contains('"' + $relative + '"')) { $errorsFound += "Project missing from solution: $relative" }
    [xml]$xml = Get-Content -LiteralPath $project.FullName -Raw
    foreach ($reference in $xml.SelectNodes('//ProjectReference')) {
        if (-not (Test-Path -LiteralPath (Join-Path $project.DirectoryName $reference.Include))) { $errorsFound += "Missing project reference in $relative" }
    }
}
$docs = @($files | Where-Object { $_.Extension -eq '.md' })
foreach ($group in ($docs | Group-Object Name | Where-Object Count -gt 1)) { $errorsFound += "Repeated document name: $($group.Name)" }
foreach ($doc in $docs) {
    $text = Get-Content -LiteralPath $doc.FullName -Raw
    foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Split('#')[0]
        if ($target -and $target -notmatch '^\w+://' -and -not (Test-Path -LiteralPath (Join-Path $doc.DirectoryName $target))) { $errorsFound += "Broken link in $($doc.Name): $target" }
    }
}
# Identical project XML can be legitimate; never delete it as duplicate source.
$duplicates = $files | Where-Object { $_.Length -gt 0 -and $_.Extension -ne '.csproj' } | Get-FileHash | Group-Object Hash | Where-Object Count -gt 1
foreach ($group in $duplicates) { $errorsFound += 'Review identical files: ' + ($group.Group.Path -join ', ') }
if ($errorsFound.Count) { $errorsFound | ForEach-Object { Write-Output "ERROR: $_" }; exit 1 }
Write-Output "Structure OK: $($projects.Count) projects, valid references and documentation links; no redundant documents."
