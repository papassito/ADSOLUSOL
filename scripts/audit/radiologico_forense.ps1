<#
================================================================================
  ADSOLUSOL :: RADIOLOGIA FORENSE DE PRECISION MILIMETRICA
  Diagnostico de punto exacto: Archivo, Linea, Columna y Causa Raiz
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Path = "."
)

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

$RootPath = (Resolve-Path $Path).Path
Set-Location $RootPath

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Magenta
Write-Host "   ADSOLUSOL :: REPORTE RADIOLOGICO Y PUNTO EXACTO DE IMPACTO     " -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta
Write-Host "Directorio base: $RootPath`n" -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# 1. RADIOGRAFIA MOJIBAKE: App.tsx
# -----------------------------------------------------------------------------
Write-Host ">>> [1/3] EXAMEN RADIOLOGICO: src/ADSOLUSOL.Presentation.Web/src/App.tsx" -ForegroundColor Yellow
$appTsxPath = Join-Path $RootPath "src/ADSOLUSOL.Presentation.Web/src/App.tsx"
if (Test-Path $appTsxPath) {
    $lines = @(Get-Content $appTsxPath -Encoding UTF8)
    $found = 0
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match "(\u00C3[\u0080-\u00BF]|\u00E2\u0088\u009E|\u00F0\u0178|\u00E2\u20AC)") {
            $found++
            $col = $line.IndexOf([string]$Matches[1]) + 1
            Write-Host "  -> [Linea $lineNum, Col $col] Secuencia corrupta detectada: '$($Matches[1])'" -ForegroundColor Red
            Write-Host "     Codigo: $($line.Trim())" -ForegroundColor DarkGray
        }
    }
    if ($found -eq 0) {
        Write-Host "  [LIMPIO] No se encontraron patrones corruptos en App.tsx." -ForegroundColor Green
    }
} else {
    Write-Host "  [NO ENCONTRADO] Archivo App.tsx no localizado." -ForegroundColor Red
}

# -----------------------------------------------------------------------------
# 2. RADIOGRAFIA MOJIBAKE: docs/EXPEDIENTE_CLINICO_MAESTRO.md
# -----------------------------------------------------------------------------
Write-Host "`n>>> [2/3] EXAMEN RADIOLOGICO: docs/EXPEDIENTE_CLINICO_MAESTRO.md" -ForegroundColor Yellow
$expPath = Join-Path $RootPath "docs/EXPEDIENTE_CLINICO_MAESTRO.md"
if (Test-Path $expPath) {
    $lines = @(Get-Content $expPath -Encoding UTF8)
    $found = 0
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($lineNum -gt 50) { break }
        if ($line -match "(\u00C3[\u0080-\u00BF]|\u00E2\u0088\u009E|\u00F0\u0178|\u00E2\u20AC)") {
            $found++
            $col = $line.IndexOf([string]$Matches[1]) + 1
            Write-Host "  -> [Linea $lineNum, Col $col] Secuencia corrupta: '$($Matches[1])'" -ForegroundColor Red
            Write-Host "     Codigo: $($line.Trim())" -ForegroundColor DarkGray
        }
    }
    if ($found -gt 0) {
        Write-Host "  [DIAGNOSTICO] Generado por proceso con codificacion ANSI/CP1252. Ejecute ./junta_medica.ps1 para regenerarlo limpio en UTF-8." -ForegroundColor DarkYellow
    } else {
        Write-Host "  [LIMPIO] Expediente clinico sin anomalias de codificacion." -ForegroundColor Green
    }
} else {
    Write-Host "  [NO ENCONTRADO] docs/EXPEDIENTE_CLINICO_MAESTRO.md ausente." -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 3. RADIOGRAFIA DE CONTRATO: CampaignRepository.cs
# -----------------------------------------------------------------------------
Write-Host "`n>>> [3/3] EXAMEN RADIOLOGICO DE CONTRATO: CampaignRepository.cs" -ForegroundColor Yellow
$campRepo = Join-Path $RootPath "src/ADSOLUSOL.Infrastructure/Repositories/CampaignRepository.cs"
if (Test-Path $campRepo) {
    $lines = @(Get-Content $campRepo -Encoding UTF8)
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line -match "public\s+async\s+Task\s+CreateAsync") {
            Write-Host "  -> [Linea $lineNum] Contrato detectado:" -ForegroundColor Cyan
            Write-Host "     $($line.Trim())" -ForegroundColor White
            Write-Host "  [ANALISIS DE CAUSA RAIZ]:" -ForegroundColor Yellow
            Write-Host "     Campaign usa GUID (string Id). Su signatura canonica es 'Task CreateAsync(Campaign c)'." -ForegroundColor Gray
            Write-Host "     El script 'Verificar-Errores.ps1' aplico la regla de Placement/Creative (que tienen ID long)" -ForegroundColor Gray
            Write-Host "     a todas las entidades por error. Requiere acotar el filtro a repositorios autonuméricos." -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  [NO ENCONTRADO] CampaignRepository.cs no localizado." -ForegroundColor Red
}

Write-Host "`n==================================================================" -ForegroundColor Magenta
Write-Host "                   FIN DEL EXAMEN RADIOLOGICO                    " -ForegroundColor Magenta
Write-Host "==================================================================`n" -ForegroundColor Magenta