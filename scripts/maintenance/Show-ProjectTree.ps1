<#
================================================================================
  ADSOLUSOL - PROJECT TREE AUDITOR
  Genera una vista de árbol del repositorio, ignorando artefactos de
  compilación y directorios de dependencias.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [int]$Depth = 5,
    [string]$OutFile,
    [string[]]$Exclude = @(
        ".git", "bin", "obj", ".vs", ".idea", "node_modules",
        "BUILD", "dist", "artifacts", "testresults", "TestResults",
        "coverage", ".tmp_build", "__pycache__", ".repair-backups",
        "_audit"
    )
)

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Get-Location).Path
}

function Show-TreeInternal {
    param(
        [string]$Path,
        [int]$MaxDepth,
        [string[]]$CurrentExclude,
        [int]$CurrentDepth = 0,
        [string]$Prefix = ""
    )

    if ($CurrentDepth -ge $MaxDepth) { return }

    $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $CurrentExclude }
    $itemCount = $items.Count
    $i = 0

    foreach ($item in $items) {
        $i++
        $isLast = ($i -eq $itemCount)
        
        $lastMarker = "$([char]0x2514)$([char]0x2500)$([char]0x2500) "  # "└── "
        $midMarker  = "$([char]0x251C)$([char]0x2500)$([char]0x2500) "  # "├── "
        $linePrefix = $Prefix + $(if ($isLast) { $lastMarker } else { $midMarker })
        
        $color = if ($item.PSIsContainer) { "Cyan" } else { "Gray" }
        Write-Host "$linePrefix" -NoNewline
        Write-Host $item.Name -ForegroundColor $color

        if ($item.PSIsContainer) {
            $continueMarker = "$([char]0x2502)   " # "│   "
            $emptyMarker    = "    "
            $newPrefix = $Prefix + $(if ($isLast) { $emptyMarker } else { $continueMarker })
            Show-TreeInternal -Path $item.FullName -MaxDepth $MaxDepth -CurrentExclude $CurrentExclude -CurrentDepth ($CurrentDepth + 1) -Prefix $newPrefix
        }
    }
}

function Get-TreeLines {
    [CmdletBinding()]
    param(
        [string]$Path,
        [int]$MaxDepth,
        [string[]]$CurrentExclude,
        [int]$CurrentDepth = 0,
        [string]$Prefix = ""
    )

    if ($CurrentDepth -ge $MaxDepth) { return }

    $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $CurrentExclude }
    $itemCount = $items.Count
    $i = 0
    $lines = [System.Collections.Generic.List[string]]::new()

    foreach ($item in $items) {
        $i++
        $isLast = ($i -eq $itemCount)
        
        $lastMarker = "$([char]0x2514)$([char]0x2500)$([char]0x2500) "  # "└── "
        $midMarker  = "$([char]0x251C)$([char]0x2500)$([char]0x2500) "  # "├── "
        $linePrefix = $Prefix + $(if ($isLast) { $lastMarker } else { $midMarker })
        
        $lines.Add("$linePrefix$($item.Name)")

        if ($item.PSIsContainer) {
            $continueMarker = "$([char]0x2502)   " # "│   "
            $emptyMarker    = "    "
            $newPrefix = $Prefix + $(if ($isLast) { $emptyMarker } else { $continueMarker })
            $lines.AddRange((Get-TreeLines -Path $item.FullName -MaxDepth $MaxDepth -CurrentExclude $CurrentExclude -CurrentDepth ($CurrentDepth + 1) -Prefix $newPrefix))
        }
    }
    return $lines.ToArray()
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL - REPOSITORY STRUCTURE AUDIT (TREE)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Root: $Root" -ForegroundColor DarkGray
Write-Host "Depth: $Depth`n" -ForegroundColor DarkGray

if ($PSBoundParameters.ContainsKey('OutFile')) {
    $outputLines = Get-TreeLines -Path $Root -MaxDepth $Depth -CurrentExclude $Exclude
    $header = '```text' + [System.Environment]::NewLine
    $footer = [System.Environment]::NewLine + '```'
    $fileContent = $header + ($outputLines -join [System.Environment]::NewLine) + $footer
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutFile, $fileContent, $utf8NoBom)
    Write-Host ('[SUCCESS] La estructura del proyecto ha sido exportada a: {0}' -f $OutFile) -ForegroundColor Green
} else {
    Show-TreeInternal -Path $Root -MaxDepth $Depth -CurrentExclude $Exclude
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Tree audit complete." -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
