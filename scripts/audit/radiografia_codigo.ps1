<#
================================================================================
  ADSOLUSOL :: RADIOGRAFIA FORENSE DE CODIGO (DETALLE TOTAL TODITITO)
  Inspecciona byte a byte y linea a linea la presencia de \uFFFD (0xEF 0xBF 0xBD)
  y secuencias de Mojibake.

  Uso:
    .\radiografia_codigo.ps1              # Escaneo profundo a TODO el proyecto
    .\radiografia_codigo.ps1 -Fix         # Repara automaticamente los errores
    .\radiografia_codigo.ps1 -Path "src\ADSOLUSOL.Presentation.Api\App.razor"
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [string]$Path = "",
    [switch]$Fix
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Registrar proveedor de páginas de códigos para soportar Windows-1252 en .NET Core / .NET 8
try {
    [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
} catch {}

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🔬 ADSOLUSOL :: RADIOGRAFIA FORENSE DE CODIGO (DETALLE TOTAL EXTREMO)    " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

# Si el usuario especifica un archivo único, se escanea solo ese.
# Si no, se escanean los que fallaron en audit-live + todos los archivos fuente clave del repo.
if (-not [string]::IsNullOrWhiteSpace($Path)) {
    $ArchivosObjetivo = @($Path)
} else {
    $Extensiones = @("*.cs", "*.razor", "*.md", "*.json", "*.ps1", "*.ts", "*.tsx", "*.html")
    $ArchivosObjetivo = Get-ChildItem -Path $ScriptRoot -Recurse -Include $Extensiones -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -notmatch '[\\/](\.git|bin|obj|node_modules|dist|BUILD)[\\/]' } | 
        ForEach-Object { $_.FullName.Substring($ScriptRoot.Length).TrimStart('\', '/') }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$ArchivosProcesados = 0
$ArchivosCorruptos = 0
$TotalHallazgos = 0

foreach ($relPath in $ArchivosObjetivo) {
    $fullPath = Join-Path $ScriptRoot $relPath

    if (-not (Test-Path $fullPath)) {
        Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "[ARCHIVO NO ENCONTRADO] $relPath" -ForegroundColor Red
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    $rawText = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
    $lines = [System.IO.File]::ReadAllLines($fullPath, [System.Text.Encoding]::UTF8)
    $hallazgosArchivo = 0

    # Primer chequeo rápido para no saturar pantalla con archivos 100% limpios
    $tieneFFFD = $rawText.Contains([char]0xFFFD)
    $tieneMojibake = $rawText -match "(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})"

    if (-not $tieneFFFD -and -not $tieneMojibake) {
        continue # Si está totalmente limpio, se omite silenciosamente para resaltar solo lo corrupto
    }

    $ArchivosCorruptos++
    $ArchivosProcesados++

    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " 💥 ARCHIVO CON ANOMALIAS DETECTADO: $relPath" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " TAMAÑO TOTAL: $($bytes.Length) Bytes | TOTAL LINEAS: $($lines.Length)" -ForegroundColor DarkGray

    # 1. ESCANEO BYTE A BYTE POR \uFFFD (0xEF 0xBF 0xBD)
    Write-Host "`n [SECCION 1: ANÁLISIS DE BYTES 0xEF 0xBF 0xBD (\uFFFD)]" -ForegroundColor Magenta
    for ($i = 0; $i -lt ($bytes.Length - 2); $i++) {
        if ($bytes[$i] -eq 0xEF -and $bytes[$i+1] -eq 0xBF -and $bytes[$i+2] -eq 0xBD) {
            $hallazgosArchivo++
            $TotalHallazgos++
            
            # Ventana HEX de contexto (-4 bytes antes, +6 bytes después)
            $startHex = [Math]::Max(0, ($i - 4))
            $endHex   = [Math]::Min(($bytes.Length - 1), ($i + 6))
            $hexWindow = ($bytes[$startHex..$endHex] | ForEach-Object { "{0:X2}" -f $_ }) -join " "

            # Ventana de texto string decodificada alrededor
            $startTxt = [Math]::Max(0, $i - 15)
            $lenTxt   = [Math]::Min($bytes.Length - $startTxt, 35)
            $txtSnippet = [System.Text.Encoding]::UTF8.GetString($bytes, $startTxt, $lenTxt).Replace("`r", "").Replace("`n", " ")

            Write-Host "  📌 OFFSET BYTE: $i (0x$("{0:X}" -f $i))" -ForegroundColor Red
            Write-Host "     HEX ENTORNO : [ $hexWindow ]" -ForegroundColor DarkGray
            Write-Host "     TEXTO VECINO: '...$txtSnippet...'" -ForegroundColor Gray
        }
    }

    # 2. ESCANEO LINEA A LINEA POR NUMERO DE LINEA, COLUMNA Y CONTENIDO EXACTO
    Write-Host "`n [SECCION 2: UBICACION EXACTA POR LINEA Y COLUMNA]" -ForegroundColor Magenta
    for ($lineNum = 0; $lineNum -lt $lines.Length; $lineNum++) {
        $currentLine = $lines[$lineNum]
        $numero = $lineNum + 1

        # A. Detección de \uFFFD en línea
        if ($currentLine.Contains([char]0xFFFD)) {
            $col = $currentLine.IndexOf([char]0xFFFD) + 1
            Write-Host "  ❌ [Línea $numero, Columna $col] Carácter corrupto \uFFFD" -ForegroundColor Red
            Write-Host "     CONTENIDO: $($currentLine.Trim())" -ForegroundColor Gray
        }

        # B. Detección de Mojibake (UTF-8 interpretado como Windows-1252)
        if ($currentLine -match "(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})") {
            $hallazgosArchivo++
            $TotalHallazgos++
            Write-Host "  ⚠️ [Línea $numero] Secuencia Mojibake detectada: '$($Matches[0])'" -ForegroundColor Yellow
            Write-Host "     CONTENIDO: $($currentLine.Trim())" -ForegroundColor Gray
        }
    }

    # 3. REPARACION AUTOMATICA SI SE ACTIVA -Fix
    if ($Fix) {
        Write-Host "`n [REPARANDO ARCHIVO...]" -ForegroundColor Cyan
        $cleanedText = $rawText.Replace([string][char]0xFFFD, "")
        
        if ($cleanedText -match "(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})") {
            try {
                $bytesBroken = [System.Text.Encoding]::GetEncoding(1252).GetBytes($cleanedText)
                $cleanedText = [System.Text.Encoding]::UTF8.GetString($bytesBroken)
            } catch {}
        }
        
        [System.IO.File]::WriteAllText($fullPath, $cleanedText, $utf8NoBom)
        Write-Host "  ✅ Archivo saneado y reescrito exitosamente en UTF-8 sin BOM." -ForegroundColor Green
    }
    Write-Host ""
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " RESUMEN FORENSE FINAL DE RADIOGRAFÍA EXTREMA" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Archivos analizados con anomalías : $ArchivosCorruptos" -ForegroundColor Yellow
Write-Host " Total de caracteres corruptos/bytes: $TotalHallazgos" -ForegroundColor Red

if ($ArchivosCorruptos -eq 0) {
    Write-Host "`n ¡TODO EL PROYECTO ESTA 100% LIMPIO! Sin \uFFFD ni Mojibake." -ForegroundColor Green
} elseif (-not $Fix) {
    Write-Host "`n Tip: Ejecuta '.\radiografia_codigo.ps1 -Fix' para reparar automáticamente todos los archivos." -ForegroundColor Yellow
}
Write-Host "==========================================================================" -ForegroundColor Cyan