Write-Host ">>> Iniciando limpieza de codificacion y BOM UTF-8..." -ForegroundColor Cyan

$RootPath = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = (Get-Location).Path }

$validExtensions = @(".cs", ".csproj", ".json", ".md", ".ps1")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$targetFiles = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { 
        $validExtensions -contains $_.Extension -and 
        $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" 
    }

$cleanedCount = 0
foreach ($file in $targetFiles) {
    if ($file.Length -eq 0) { continue }

    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes.Length -eq 0) { continue }

    $hadBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    
    $cleanBytes = if ($hadBom) {
        if ($bytes.Length -gt 3) {
            [byte[]]$bytes[3..($bytes.Length - 1)]
        } else {
            [byte[]]@()
        }
    } else {
        $bytes
    }

    if ($cleanBytes.Length -eq 0) { continue }
    $text = [System.Text.Encoding]::UTF8.GetString($cleanBytes)
    $sanitizedText = $text.TrimStart([char]0xFEFF, [char]0x00BF, [char]0xFFFD)
    
    if ($hadBom -or ($sanitizedText.Length -ne $text.Length)) {
        [System.IO.File]::WriteAllText($file.FullName, $sanitizedText, $utf8NoBom)
        $cleanedCount++
        $rel = $file.FullName.Replace($RootPath, "")
        Write-Host " [OK] Saneado: $rel" -ForegroundColor Green
    }
}

Write-Host ">>> Limpieza completada. $cleanedCount archivo(s) saneados." -ForegroundColor Cyan