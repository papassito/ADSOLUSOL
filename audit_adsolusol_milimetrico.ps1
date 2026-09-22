# ==============================================================================
# INSPECTOR-FORENSE-ULTRA.ps1
# Auditoría milimétrica y sin filtros para la solución ADSOLUSOL
# ==============================================================================

[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$totalErrors = 0$findingsList = [System.Collections.Generic.List[string]]::new()

function Write-Header([string]$title) {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " $title" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
}

function Report-Finding([string]$severity, [string]$component, [string]$message) {$script:totalErrors++
    $formatted = "[$severity] [$component]$message"
    $script:findingsList.Add($formatted)
    
    $color = switch ($severity) {
        "CRITICAL" { "Red" }
        "HIGH"     { "DarkRed" }
        "MEDIUM"   { "Yellow" }
        default    { "Gray" }
    }
    Write-Host "  -> $formatted" -ForegroundColor $color
}

# ------------------------------------------------------------------------------
# 1. SETUP Y VERIFICACIÓN DE ENTORNO
# ------------------------------------------------------------------------------
Write-Header "1. ANÁLISIS DE ENTORNO Y RAÍZ"

if (-not (Test-Path $Root)) {
    Write-Host "[CRÍTICO] La ruta especificada no existe: $Root" -ForegroundColor Red
    exit 1
}

$dotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
if (-not $dotnetCmd) {
    Report-Finding "CRITICAL" "ENTORNO" "dotnet SDK no está disponible en el PATH."
    exit 1
} else {
    Write-Host "[OK] .NET Executable: $($dotnetCmd.Source)" -ForegroundColor Green
    $sdkVer = & dotnet --version 2>&1
    Write-Host "[OK] .NET SDK Version: $sdkVer" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 2. AUDITORÍA ESTRUCTURAL Y DE ARCHIVOS CORRUPTOS/HUÉRFANOS
# ------------------------------------------------------------------------------
Write-Header "2. DETECCIÓN DE ANOMALÍAS ESTRUCTURALES Y ARCHIVOS CORRUPTOS"

# 2.1 Proyectos en la raíz del repositorio (Captura masiva no deseada)
$rootCsproj = Get-ChildItem -Path$Root -Filter "*.csproj" -File
foreach ($proj in$rootCsproj) {
    Report-Finding "CRITICAL" "ESTRUCTURA" "Proyecto `.csproj` detectado en la RAÍZ ($($proj.Name)). MSBuild capturará y duplicará todos los archivos .cs del repositorio."
}

# 2.2 Proyectos vacíos (0 bytes) o XML corrupto
$allCsproj = Get-ChildItem -Path$Root -Filter "*.csproj" -Recurse
foreach ($proj in$allCsproj) {
    if ($proj.Length -eq 0) {
        Report-Finding "CRITICAL" "ESTRUCTURA" "El archivo de proyecto está VACÍO (0 bytes): $($proj.FullName)"
    } else {
        try {
            [xml]$xml = Get-Content$proj.FullName -ErrorAction Stop
        } catch {
            Report-Finding "CRITICAL" "ESTRUCTURA" "El archivo de proyecto contiene XML corrupto/inválido: $($proj.FullName)"
        }
    }
}

# 2.3 Archivos .csproj duplicados o en carpetas incorrectas
$apiFolderDesktopProj = Join-Path$Root "src\ADSOLUSOL.Presentation.Api\ADSOLUSOL.Presentation.Desktop.csproj"
if (Test-Path $apiFolderDesktopProj) {
    Report-Finding "CRITICAL" "ESTRUCTURA" "Existe un archivo de proyecto duplicado/fuera de lugar en la API: $apiFolderDesktopProj"
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN DE CONTRATOS E INTERFACES (FIRMAS DESALINEADAS)
# ------------------------------------------------------------------------------
Write-Header "3. ANÁLISIS DE CONTRATOS, INTERFACES E IMPLEMENTACIONES"

$csFiles = Get-ChildItem -Path$Root -Filter "*.cs" -Recurse

# Escaneo de CreativeRepository y PlacementRepository para retorno de Task<long>
foreach ($cs in$csFiles) {
    $content = Get-Content$cs.FullName -Raw -ErrorAction SilentlyContinue
    if ($null -ne$content) {
        if ($cs.Name -eq "CreativeRepository.cs" -or $cs.Name -eq "PlacementRepository.cs") {
            if ($content -match 'public\s+async\s+Task\s+CreateAsync') {
                Report-Finding "CRITICAL" "REPOSITORIO" "$($cs.Name) implementa 'Task CreateAsync' en lugar de 'Task<long> CreateAsync', violando el contrato de la interfaz."
            }
        }
    }
}

# ------------------------------------------------------------------------------
# 4. AUDITORÍA DE INYECCIÓN DE DEPENDENCIAS (DI) EN PUNTOS DE ENTRADA
# ------------------------------------------------------------------------------
Write-Header "4. AUDITORÍA DE CONTENEDORES DE INYECCIÓN DE DEPENDENCIAS"

$mauiProgram = Get-ChildItem -Path$Root -Filter "MauiProgram.cs" -Recurse | Select-Object -First 1
if ($mauiProgram) {$mauiContent = Get-Content $mauiProgram.FullName -Raw$requiredServices = @("ICreativeRepository", "IPlacementRepository", "IAdEventRepository", "IAssignmentRepository", "BudgetService", "MetricsService")
    foreach ($svc in$requiredServices) {
        if ($mauiContent -notmatch$svc) {
            Report-Finding "HIGH" "INYECCION_DEP" "Falta registrar '$svc' en el contenedor DI de MAUI ($($mauiProgram.Name)). Provocará InvalidOperationException en runtime."
        }
    }
}

# ------------------------------------------------------------------------------
# 5. BARIDO DE SEGURIDAD Y SECRETOS EMBEBIDOS
# ------------------------------------------------------------------------------
Write-Header "5. ESCANEO FORENSE DE SEGURIDAD Y SECRETOS EN CÓDIGO"

$sensitivePatterns = @(
    'BEGIN PRIVATE KEY',
    '-----BEGIN RSA PRIVATE KEY-----',
    'Password\s*=\s*"[^"]{3,}"',
    'SecretKey\s*=\s*"[^"]{3,}"'
)

foreach ($cs in $csFiles) {$lines = Get-Content $cs.FullName -ErrorAction SilentlyContinue$lineNum = 0
    foreach ($line in $lines) {$lineNum++
        foreach ($pattern in$sensitivePatterns) {
            if ($line -match$pattern) {
                Report-Finding "HIGH" "SEGURIDAD" "Posible secreto hardcodeado en $($cs.Name) (Línea $lineNum): $($line.Trim())"
            }
        }
    }
}

# ------------------------------------------------------------------------------
# 6. CODE SMELLS: CATCH SILENCIOSOS, TODOs Y STUBS NO IMPLEMENTADOS
# ------------------------------------------------------------------------------
Write-Header "6. INSPECCIÓN DE PRÁCTICAS PELIGROSAS Y ANOMALÍAS DE CÓDIGO"

$stubs = @($csFiles | Select-String -Pattern "NotImplementedException" -CaseSensitive)
foreach ($stub in$stubs) {
    Report-Finding "MEDIUM" "CODE_SMELL" "NotImplementedException encontrado en $(Split-Path$stub.Path -Leaf):$($stub.LineNumber)"
}

$emptyCatches = @($csFiles | Select-String -Pattern "catch\s*\([^\)]*\)\s*\{\s*\}" -CaseSensitive)
foreach ($ec in$emptyCatches) {
    Report-Finding "MEDIUM" "CODE_SMELL" "Bloque catch silencioso (ignora errores) en $(Split-Path$ec.Path -Leaf):$($ec.LineNumber)"
}

# ------------------------------------------------------------------------------
# 7. COMPILACIÓN AISLADA PROYECTO POR PROYECTO
# ------------------------------------------------------------------------------
Write-Header "7. PRUEBA DE COMPILACIÓN EN AISLAMIENTO (PROYECTO POR PROYECTO)"

$projects = Get-ChildItem -Path$Root -Filter "*.csproj" -Recurse
foreach ($proj in$projects) {
    Write-Host -NoNewline "Probrando compilación: $($proj.Name)... "
    $buildResult = & dotnet build$proj.FullName --nologo -v:quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FALLÓ]" -ForegroundColor Red
        Report-Finding "CRITICAL" "COMPILACION" "El proyecto $($proj.Name) falló en compilación individual."
        $buildResult \vert{} Where-Object {$_ -match "error CS" -or $_ -match "error MSB" -or $_ -match "error NU" } | ForEach-Object {
            Write-Host "      -> $($_.ToString().Trim())" -ForegroundColor DarkRed
        }
    } else {
        Write-Host "[PASS]" -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# 8. RESUMEN EJECUTIVO Y VERDICTO
# ------------------------------------------------------------------------------
Write-Header "8. RESUMEN EJECUTIVO DE LA AUDITORÍA"

if ($script:totalErrors -eq 0) {
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host " VERDICTO: PROYECTO COMPLETAMENTE SANO Y LIMPIO (0 BLOQUEADORES)" -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Green
} else {
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host " VERDICTO: SE ENCONTRARON $($script:totalErrors) HALLAZGOS QUE REQUIEREN ATENCIÓN" -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "LISTADO CONSOLIDADO DE PROBLEMAS:" -ForegroundColor Yellow
    foreach ($f in$script:findingsList) {
        Write-Host " $f" -ForegroundColor Red
    }
}
Write-Host ""