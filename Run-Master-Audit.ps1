# ==============================================================================
# Run-Master-Audit.ps1
#
# Auditor Maestro Unificado para ADSOLUSOL.
# Combina análisis de compilación, pruebas, calidad de código, seguridad y
# arquitectura en un único script con reportes detallados.
# ==============================================================================

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$CI_MODE # Si se especifica, usa exit code y no espera al usuario
)

# --- CONFIGURACIÓN INICIAL ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# --- ESTRUCTURA DE HALLAZGOS ---
$findings = @{
    BuildErrors        = @()
    TestFailures       = [System.Collections.Generic.List[string]]::new()
    CodeQuality        = [System.Collections.Generic.List[string]]::new()
    Security           = [System.Collections.Generic.List[string]]::new()
    Architecture       = [System.Collections.Generic.List[string]]::new()
    AllFindingsList    = [System.Collections.Generic.List[string]]::new()
    Metrics            = @{}
    BuildStatus        = "PENDING"
    TestStatus         = "PENDING"
}

# --- FUNCIONES DE AYUDA ---
function Write-Header([string]$title) {
    Write-Host "`n==========================================================================" -ForegroundColor Cyan
    Write-Host " $title" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
}

function Report-Finding([string]$severity, [string]$component, [string]$message) {
    $formattedMessage = "[$severity] [$component] $message"
    $findings.AllFindingsList.Add($formattedMessage)

    $color = switch ($severity) {
        "CRITICAL" { "Red" }
        "HIGH"     { "DarkRed" }
        "MEDIUM"   { "Yellow" }
        default    { "Gray" }
    }
    Write-Host "  -> $formattedMessage" -ForegroundColor $color

    switch ($component) {
        "SEGURIDAD"    { $findings.Security.Add($formattedMessage) }
        "ARQUITECTURA" { $findings.Architecture.Add($formattedMessage) }
        "CALIDAD"      { $findings.CodeQuality.Add($formattedMessage) }
    }
}

Write-Header "🕵️‍♂️ AUDITORÍA MAESTRA UNIFICADA — ADSOLUSOL"
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
Write-Host "[INFO] Raíz de análisis: $Root`n" -ForegroundColor Gray

# ==============================================================================
# FASE 1: PREPARACIÓN Y MÉTRICAS
# ==============================================================================
Write-Header "FASE 1: PREPARACIÓN Y MÉTRICAS"

$dotnetExe = Get-Command "dotnet" -ErrorAction SilentlyContinue
if (-not $dotnetExe) {
    Write-Host "[CRÍTICO] No se localizó 'dotnet.exe'. La auditoría no puede continuar." -ForegroundColor Red
    exit 1
}
Write-Host "[✓] .NET SDK detectado en: $($dotnetExe.Source)" -ForegroundColor Green

$slnPath = Get-ChildItem -Path $Root -Filter "*.sln" -Recurse | Select-Object -First 1
if (-not $slnPath) {
    Write-Host "[CRÍTICO] No se encontró ningún archivo .sln. La auditoría no puede continuar." -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Solución bajo análisis: $($slnPath.FullName)" -ForegroundColor Green

$csharpFiles = Get-ChildItem -Path $Root -Filter "*.cs" -Recurse
$totalLines = if ($csharpFiles) { ($csharpFiles | Get-Content | Measure-Object -Line).Lines } else { 0 }
$findings.Metrics.ArchivosCSharp = $csharpFiles.Count
$findings.Metrics.LineasDeCodigo = $totalLines
Write-Host "[✓] Se analizarán $($csharpFiles.Count) archivos C# con $totalLines líneas de código." -ForegroundColor Green

# ==============================================================================
# FASE 2: ANÁLISIS DE COMPILACIÓN
# ==============================================================================
Write-Header "FASE 2: ANÁLISIS DE COMPILACIÓN"

$buildLog = & $dotnetExe build "$($slnPath.FullName)" -v:normal /noconlog 2>&1
$buildExitCode = $LASTEXITCODE

$errorRegex = '^(?<file>.*?\.cs)\((?<line>\d+),(?<col>\d+)\):\s+error\s+(?<code>CS\d+):\s+(?<msg>.*)$'
foreach ($line in $buildLog) {
    if ($line -match $errorRegex) {
        $findings.BuildErrors += [PSCustomObject]@{
            Archivo = $Matches['file']
            Linea   = $Matches['line']
            Codigo  = $Matches['code']
            Mensaje = $Matches['msg'].Trim()
        }
    }
}

if ($buildExitCode -eq 0) {
    Write-Host "[✓] ¡ÉXITO! La solución compila sin errores." -ForegroundColor Green
    $findings.BuildStatus = "OK"
} else {
    Write-Host "[!] FALLO. 'dotnet build' falló (Exit Code: $buildExitCode)." -ForegroundColor Red
    $findings.BuildStatus = "FAIL"
    $findings.AllFindingsList.Add("[CRITICAL] [BUILD] La compilación falló con exit code $buildExitCode.")
}

# ==============================================================================
# FASE 3: ANÁLISIS FORENSE (ESTRUCTURA, SEGURIDAD, CALIDAD)
# ==============================================================================
Write-Header "FASE 3: ANÁLISIS FORENSE (ESTRUCTURA, SEGURIDAD, CALIDAD)"

# --- 3.1. Análisis Estructural ---
$allCsproj = Get-ChildItem -Path $Root -Filter "*.csproj" -Recurse
foreach ($proj in $allCsproj) {
    if ($proj.Directory.FullName -eq (Resolve-Path $Root)) {
        Report-Finding "CRITICAL" "ARQUITECTURA" "Proyecto .csproj en la RAÍZ ($($proj.Name)). Esto puede causar errores de compilación por duplicados."
    }
    if ($proj.Length -eq 0) {
        Report-Finding "CRITICAL" "ARQUITECTURA" "El archivo de proyecto está VACÍO (0 bytes): $($proj.FullName)"
    }
}

# --- 3.2. Análisis de Seguridad (Secretos) ---
$sensitivePatterns = @{
    'BEGIN (RSA )?PRIVATE KEY' = 'Clave privada encontrada';
    'Password\s*=\s*"[^"]{4,}"' = 'Posible contraseña en texto plano';
    'SecretKey\s*=\s*"[^"]{4,}"' = 'Posible clave secreta en texto plano';
}
foreach ($csFile in $csharpFiles) {
    $fileContent = Get-Content $csFile.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($pattern in $sensitivePatterns.Keys) {
        if ($fileContent -match $pattern) {
            Report-Finding "HIGH" "SEGURIDAD" "$($sensitivePatterns[$pattern]) en el archivo $($csFile.Name)."
        }
    }
}

# --- 3.3. Análisis de Calidad (Code Smells) ---
$csharpFiles | Select-String -Pattern "NotImplementedException" | ForEach-Object {
    Report-Finding "MEDIUM" "CALIDAD" "NotImplementedException en $(Split-Path $_.Path -Leaf):$($_.LineNumber)"
}
$csharpFiles | Select-String -Pattern "catch\s*\([^\)]*\)\s*\{\s*\}" | ForEach-Object {
    Report-Finding "MEDIUM" "CALIDAD" "Bloque catch silencioso (ignora errores) en $(Split-Path $_.Path -Leaf):$($_.LineNumber)"
}
$csharpFiles | Select-String -Pattern "TODO|FIXME" | ForEach-Object {
    Report-Finding "LOW" "CALIDAD" "Comentario TODO/FIXME en $(Split-Path $_.Path -Leaf):$($_.LineNumber) -> $($_.Line.Trim())"
}

# --- 3.4. Análisis de Contratos y DI ---
# Verificación de firma en repositorios
$repoFiles = $csharpFiles | Where-Object { $_.Name -in "CreativeRepository.cs", "PlacementRepository.cs" }
foreach ($repo in $repoFiles) {
    if ((Get-Content $repo.FullName -Raw) -match 'public\s+async\s+Task\s+CreateAsync') {
        Report-Finding "CRITICAL" "ARQUITECTURA" "$($repo.Name) implementa 'Task CreateAsync' en lugar de 'Task<long> CreateAsync', violando el contrato."
    }
}

# Verificación de DI en MauiProgram
$mauiProgram = $csharpFiles | Where-Object { $_.Name -eq "MauiProgram.cs" } | Select-Object -First 1
if ($mauiProgram) {
    $mauiContent = Get-Content $mauiProgram.FullName -Raw
    $requiredServices = @("ICreativeRepository", "IPlacementRepository", "BudgetService", "MetricsService")
    foreach ($svc in $requiredServices) {
        if ($mauiContent -notmatch "AddScoped.*<\s*$svc") {
            Report-Finding "HIGH" "ARQUITECTURA" "Falta registrar '$svc' en el contenedor DI de MAUI ($($mauiProgram.Name))."
        }
    }
}

# ==============================================================================
# FASE 4: EJECUCIÓN DE PRUEBAS
# ==============================================================================
Write-Header "FASE 4: EJECUCIÓN DE PRUEBAS"

if ($findings.BuildStatus -ne "OK") {
    Write-Host "[SKIP] Se omiten las pruebas debido a un fallo de compilación." -ForegroundColor Gray
    $findings.TestStatus = "SKIPPED"
} else {
    $testProjects = Get-ChildItem -Path $Root -Filter "*Test*.csproj" -Recurse
    if (-not $testProjects) {
        Write-Host "[INFO] No se localizaron proyectos de prueba." -ForegroundColor Gray
        $findings.TestStatus = "NO_TESTS_FOUND"
    } else {
        $allTestsPassed = $true
        foreach ($testProj in $testProjects) {
            Write-Host "`n  📌 Ejecutando Suite: $($testProj.Name)" -ForegroundColor Cyan
            $testOutput = & $dotnetExe test "$($testProj.FullName)" --no-build -v:q --nologo 2>&1
            if ($LASTEXITCODE -ne 0) {
                $allTestsPassed = $false
                $failMsg = "[FAIL] [TESTS] La suite '$($testProj.Name)' falló."
                $findings.TestFailures.Add($failMsg)
                $findings.AllFindingsList.Add($failMsg)
                Write-Host "    [FAIL] La suite falló." -ForegroundColor Red
                $testOutput | Where-Object { $_ -match "Failed|Exception|Stack Trace" } | ForEach-Object {
                    $findings.TestFailures.Add("      -> $_")
                }
            } else {
                Write-Host "    [PASS] Suite completada exitosamente." -ForegroundColor Green
            }
        }
        $findings.TestStatus = if ($allTestsPassed) { "PASS" } else { "FAIL" }
    }
}

# ==============================================================================
# FASE 5: INFORME FINAL DE AUDITORÍA
# ==============================================================================
Write-Header "📋 INFORME FINAL DE AUDITORÍA MAESTRA"

# --- Métricas ---
Write-Host "📊 MÉTRICAS DEL CÓDIGO" -ForegroundColor Cyan
Write-Host "   ├── Archivos C#      : $($findings.Metrics.ArchivosCSharp)"
Write-Host "   └── Líneas de código : $($findings.Metrics.LineasDeCodigo)"

# --- Estado de Compilación ---
Write-Host "`n🛠️ ESTADO DE COMPILACIÓN: $($findings.BuildStatus)" -ForegroundColor $(if ($findings.BuildStatus -eq 'OK') {'Green'} else {'Red'})
if ($findings.BuildErrors.Count -gt 0) {
    $findings.BuildErrors | Group-Object Archivo | ForEach-Object {
        Write-Host "   📄 ARCHIVO: $($_.Name)" -ForegroundColor Yellow
        foreach ($err in $_.Group) {
            Write-Host "      ├── Línea $($err.Linea): [$($err.Codigo)] $($err.Mensaje)" -ForegroundColor Red
        }
    }
}

# --- Estado de Pruebas ---
$testColor = "Green"
if ($findings.TestStatus -eq 'FAIL') { $testColor = "Red" }
if ($findings.TestStatus -eq 'SKIPPED') { $testColor = "Gray" }
Write-Host "`n🧪 ESTADO DE PRUEBAS: $($findings.TestStatus)" -ForegroundColor $testColor
if ($findings.TestFailures.Count -gt 0) {
    $findings.TestFailures | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
}

# --- Hallazgos Forenses ---
function Print-Findings([string]$title, [System.Collections.Generic.List[string]]$collection) {
    if ($collection.Count -gt 0) {
        Write-Host "`n$title ($($collection.Count))" -ForegroundColor Yellow
        $collection | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
    }
}

Print-Findings "🏛️ HALLAZGOS DE ARQUITECTURA" $findings.Architecture
Print-Findings "🛡️ HALLAZGOS DE SEGURIDAD" $findings.Security
Print-Findings "🤔 HALLAZGOS DE CALIDAD DE CÓDIGO" $findings.CodeQuality

# ==============================================================================
# FASE 6: VEREDICTO Y GENERACIÓN DE REPORTES
# ==============================================================================
Write-Header "🏁 VEREDICTO FINAL Y REPORTES"

$finalStatus = "PASS"
if ($findings.BuildStatus -ne 'OK' -or $findings.TestStatus -eq 'FAIL' -or ($findings.AllFindingsList | Where-Object { $_ -match "CRITICAL|HIGH" })) {
    $finalStatus = "FAIL"
}

$finalColor = if ($finalStatus -eq "PASS") { "Green" } else { "Red" }
Write-Host "Resultado General de la Auditoría: " -NoNewline
Write-Host $finalStatus -ForegroundColor $finalColor

# --- Reporte JSON ---
$reportObject = @{
    Timestamp       = (Get-Date).ToString("o")
    Project         = "ADSOLUSOL"
    Status          = $finalStatus
    Metrics         = $findings.Metrics
    Build           = @{ Status = $findings.BuildStatus; Errors = $findings.BuildErrors }
    Tests           = @{ Status = $findings.TestStatus; Failures = $findings.TestFailures }
    Forensics       = @{
        Architecture = $findings.Architecture
        Security     = $findings.Security
        CodeQuality  = $findings.CodeQuality
    }
    SummaryFindings = $findings.AllFindingsList
}

$jsonReportPath = Join-Path $Root "audit_report_master.json"
try {
    $reportObject | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonReportPath -Encoding UTF8
    Write-Host "[✓] Reporte JSON generado en: $jsonReportPath" -ForegroundColor Green
} catch {
    Write-Host "[!] No se pudo escribir el reporte JSON: $($_.Exception.Message)" -ForegroundColor Red
}

# --- Reporte Markdown ---
$mdReportPath = Join-Path $Root "audit_report_master.md"
$mdContent = @"
# 📋 Reporte de Auditoría Maestra: ADSOLUSOL
*   **Fecha:** $(Get-Date)
*   **Resultado General:** **$($reportObject.Status)**
## 📜 Resumen de Hallazgos ($($reportObject.SummaryFindings.Count))
$($reportObject.SummaryFindings | ForEach-Object { "- $_" } | Out-String)
"@
try {
    $mdContent | Set-Content -Path $mdReportPath -Encoding UTF8
    Write-Host "[✓] Reporte Markdown generado en: $mdReportPath" -ForegroundColor Green
} catch {
    Write-Host "[!] No se pudo escribir el reporte Markdown: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor $finalColor
Write-Host " FIN DE LA AUDITORÍA" -ForegroundColor $finalColor
Write-Host "==========================================================================" -ForegroundColor $finalColor

if (-not $CI_MODE) {
    Write-Host ""
    Read-Host "Presiona ENTER para cerrar"
}

if ($finalStatus -eq 'FAIL' -and $CI_MODE) {
    exit 1
}

exit 0