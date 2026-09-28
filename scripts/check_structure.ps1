$ErrorActionPreference = 'Stop'
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
if (Test-Path (Join-Path $scriptDir 'ADSOLUSOL.sln')) {
    $root = (Resolve-Path $scriptDir).Path
} else {
    $root = (Resolve-Path (Split-Path -Parent $scriptDir)).Path
}
$problems = @()
$files = @(Get-ChildItem -LiteralPath $root -File -Recurse -Force | Where-Object { $_.FullName -notmatch '[\\/](\.git|bin|obj|BUILD|\.build|\.repair-backups|node_modules|dist|coverage|\.pids)[\\/]' })

if (Test-Path -LiteralPath (Join-Path $root 'ADSOLUSOL')) { 
    $problems += 'Nested project root: ADSOLUSOL/' 
}

$slnFiles = @($files | Where-Object { $_.Name -eq 'ADSOLUSOL.sln' })
if ($slnFiles.Count -ne 1 -or $slnFiles[0].DirectoryName -ne $root) { 
    $problems += 'Expected exactly one ADSOLUSOL.sln at repository root.' 
}

$rootProjects = @(Get-ChildItem -Path $root -Filter '*.csproj' -File -ErrorAction SilentlyContinue)
if ($rootProjects.Count -gt 0) {
    foreach ($rp in $rootProjects) {
        $problems += "Orphan project found at repository root: $($rp.Name)"
    }
}

$allowedRootDocs = @(
    'README.md', 'REQUIREMENTS.md', 'MAP.md', 'ROADMAP.md', 'LIBRARY.md',
    'COMPONENTS.md', 'HISTORIAL_ACTUALIZACIONES.md', 'HISTORIAL DE ACTIVIDADES.MD',
    'MANIFEST.md', 'audit_report_adsolusol.md', 'audit_report_master.md'
)
foreach ($file in $files) {
    if ($file.Extension -eq '.md' -and $file.DirectoryName -eq $root -and $file.Name -notin $allowedRootDocs) { 
        $problems += "Place project documentation in docs/: $($file.Name)" 
    }
}

$duplicates = $files | Where-Object { $_.Length -gt 0 -and $_.Extension -in @('.cs', '.ts', '.tsx', '.json') } | Get-FileHash -Algorithm SHA256 | Group-Object Hash | Where-Object { $_.Count -gt 1 }
foreach ($group in $duplicates) { $problems += 'Review identical files: ' + (($group.Group.Path | ForEach-Object { $_.Substring($root.Length + 1) }) -join ', ') }
if ($problems.Count) { $problems | ForEach-Object { Write-Output "ERROR: $_" }; exit 1 }
Write-Output 'Structure OK: valid .NET 8 / ADSOLUSOL root; no identical nonempty source files.'
