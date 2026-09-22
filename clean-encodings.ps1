# ==============================================================================
# clean-encodings.ps1
# Remueve el encabezado UTF-8 BOM (\uFEFF) de archivos especificos
# ==============================================================================

Write-Host ">>> Iniciando limpieza de codificacion y BOM UTF-8..." -ForegroundColor Cyan

$filesToClean = @(
    "tests/ADSOLUSOL.RegressionTests/ADSOLUSOL.RegressionTests.csproj",
    "tests/ADSOLUSOL.RegressionTests/Program.cs",
    "audit_report_master.json",
    "audit_report_master.md"
)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($relativePath in $filesToClean) {
    if (Test-Path $relativePath) {
        # Leer el contenido como texto
        $content = [System.IO.File]::ReadAllText((Resolve-Path $relativePath), [System.Text.Encoding]::UTF8)
        
        # Reescribir el archivo explícitamente en UTF-8 SIN BOM
        [System.IO.File]::WriteAllText((Resolve-Path $relativePath), $content, $utf8NoBom)
        
        Write-Host " [✓] Limpiado BOM UTF-8 en: $relativePath" -ForegroundColor Green
    } else {
        Write-Host " [!] Archivo no encontrado (omitido): $relativePath" -ForegroundColor Yellow
    }
}

Write-Host ">>> Limpieza de codificacion completada." -ForegroundColor Cyan