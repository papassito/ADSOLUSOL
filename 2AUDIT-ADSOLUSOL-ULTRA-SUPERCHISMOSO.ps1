# AUDIT-ADSOLUSOL-ULTRA-SUPERCHISMOSO.ps1
#
# Un script de diagnóstico forense y auditoría de calidad de código para proyectos .NET.
# Combina análisis de compilación, ejecución de pruebas, y búsqueda de "code smells"
# para proporcionar un informe milimétrico del estado del proyecto.

[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot,
    [switch]$CI_MODE # Si se especifica, usa exit code y no espera al usuario
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Inicialización de contadores y hallazgos
$findings = @{
    BuildErrors        = @()
    TestFailures       = New-Object System.Collections.Generic.List[string]
    UnimplementedStubs = @()
    CodeTodos          = @()
    ArchFindings       = @()
    AllFindingsList    = [System.Collections.Generic.List[string]]::new()
    Metrics            = @{}
    BuildStatus        = "PENDING"
    TestStatus         = "PENDING"
}

# ==============================================================================
# BANNER
# ==============================================================================
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🕵️‍♂️ AUDITORÍA FORENSE ULTRA-CHISMOSA — ADSOLUSOL" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
Write-Host "[INFO] Raíz de análisis: $Root`n" -ForegroundColor Gray


# ==============================================================================
# 1. SETUP: LOCALIZACIÓN DE HERRAMIENTAS Y PROYECTO
# ==============================================================================
Write-Host ">>> [FASE 1] Preparando entorno de auditoría..." -ForegroundColor Yellow

# --- 1.1 Localizador robusto del SDK de .NET ---
$dotnetExe = $null
$candidatePaths = @(
    "C:\Program Files\dotnet\dotnet.exe",
    "C:\Program Files (x86)\dotnet\dotnet.exe",
    $env:ProgramFiles + "\dotnet\dotnet.exe"
)
foreach ($path in $candidatePaths) {
    if (Test-Path $path) {
        $dotnetExe = $path
        break
    }
}
if (-not $dotnetExe) {
    $dotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
    if ($dotnetCmd) { $dotnetExe = $dotnetCmd.Source }
}
if (-not $dotnetExe -or -not (Test-Path $dotnetExe)) {
    Write-Host "[CRÍTICO] No se localizó 'dotnet.exe'. La auditoría no puede continuar." -ForegroundColor Red
    exit 1
}
Write-Host "[✓] .NET SDK detectado en: $dotnetExe" -ForegroundColor Green
$sdkVer = (& $dotnetExe --version 2>&1).ToString().Trim()
Write-Host "[✓] Versión de SDK en uso: $sdkVer" -ForegroundColor Green

# --- 1.2 Localización de la solución ---
$slnPath = Get-ChildItem -Path $Root -Filter "*.sln" -Recurse | Select-Object -First 1
if (-not $slnPath) {
    Write-Host "[CRÍTICO] No se encontró ningún archivo .sln. La auditoría no puede continuar." -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Solución bajo análisis: $($slnPath.FullName)`n" -ForegroundColor Green


# ==============================================================================
# 2. MÉTRICAS DE CÓDIGO
# ==============================================================================
Write-Host ">>> [FASE 2] Calculando métricas de código fuente..." -ForegroundColor Yellow
$csharpFiles = Get-ChildItem -Path $Root -Filter "*.cs" -Recurse
$totalLines = 0
if ($csharpFiles) {
    $totalLines = ($csharpFiles | Get-Content | Measure-Object -Line).Lines
}
$findings.Metrics.ArchivosCSharp = $csharpFiles.Count
$findings.Metrics.LineasDeCodigo = $totalLines
Write-Host "[INFO] Se encontraron $($csharpFiles.Count) archivos C# con un total de $totalLines líneas de código.`n" -ForegroundColor Gray


# ==============================================================================
# 3. ANÁLISIS DE COMPILACIÓN (LA SOPA CRUDA)
# ==============================================================================
Write-Host ">>> [FASE 3] Ejecutando 'dotnet build' para análisis de compilación..." -ForegroundColor Yellow
$buildLogFile = Join-Path $Root "_audit_build_raw.log"
& $dotnetExe build "$($slnPath.FullName)" -v:normal /noconlog > $buildLogFile 2>&1
$buildLog = Get-Content $buildLogFile -Encoding UTF8 -ErrorAction SilentlyContinue
Remove-Item $buildLogFile -Force -ErrorAction SilentlyContinue

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

if ($findings.BuildErrors.Count -eq 0) {
    Write-Host "[✓] ¡ÉXITO! La solución compila sin errores de C#." -ForegroundColor Green
    $findings.BuildStatus = "OK"
} else {
    Write-Host "[!] FALLO. Se detectaron errores de compilación." -ForegroundColor Red
    $findings.BuildStatus = "FAIL"
}
Write-Host ""


# ==============================================================================
# 4. ANÁLISIS ESTÁTICO (CODE SMELLS Y ARQUITECTURA)
# ==============================================================================
Write-Host ">>> [FASE 4] Buscando 'code smells' y problemas de arquitectura..." -ForegroundColor Yellow

# --- 4.1 Endpoints no implementados ---
$findings.UnimplementedStubs = @($csharpFiles | Select-String -Pattern "NotImplementedException" | Select-Object Path, LineNumber, Line)
if ($findings.UnimplementedStubs.Count -gt 0) {
    Write-Host "[!] Se encontraron $($findings.UnimplementedStubs.Count) stubs con 'NotImplementedException'." -ForegroundColor Yellow
} else {
    Write-Host "[✓] No se encontraron stubs con 'NotImplementedException'." -ForegroundColor Green
}

# --- 4.2 Tareas pendientes (TODO/FIXME) ---
$findings.CodeTodos = @($csharpFiles | Select-String -Pattern "TODO|FIXME" -CaseSensitive | Select-Object Path, LineNumber, Line)
if ($findings.CodeTodos.Count -gt 0) {
    Write-Host "[!] Se encontraron $($findings.CodeTodos.Count) comentarios 'TODO' o 'FIXME'." -ForegroundColor Yellow
} else {
    Write-Host "[✓] No se encontraron comentarios 'TODO' o 'FIXME'." -ForegroundColor Green
}

# --- 4.3 Verificación de Middleware de Firma (basado en README.md) ---
$programCsFile = Get-ChildItem -Path $Root -Filter "Program.cs" -Recurse | Select-Object -First 1
if ($programCsFile) {
    $middlewareWired = Get-Content $programCsFile.FullName | Select-String -Pattern "UseMiddleware<SignatureVerificationMiddleware>" -Quiet
    if (-not $middlewareWired) {
        $msg = "El middleware 'SignatureVerificationMiddleware' no está conectado en '$($programCsFile.Name)'."
        $findings.AllFindingsList.Add("[MEDIUM] [ARQUITECTURA] $msg")
        $findings.ArchFindings += $msg
        Write-Host "[!] Hallazgo de arquitectura: $msg" -ForegroundColor Yellow
    } else {
        Write-Host "[✓] El middleware de firma parece estar conectado correctamente." -ForegroundColor Green
    }
}
Write-Host ""


# ==============================================================================
# 5. EJECUCIÓN DE PRUEBAS
# ==============================================================================
Write-Host ">>> [FASE 5] Ejecutando suites de pruebas..." -ForegroundColor Yellow
if ($findings.BuildStatus -ne "OK") {
    Write-Host "[SKIP] Se omiten las pruebas debido a un fallo de compilación." -ForegroundColor Gray
    $findings.TestStatus = "SKIPPED"
} else {
    $testProjects = Get-ChildItem -Path $Root -Filter "*Test*.csproj" -Recurse
    if (-not $testProjects) {
        Write-Host "[WARNING] No se localizaron proyectos de prueba con el patrón '*Test*'." -ForegroundColor Yellow
        $findings.AllFindingsList.Add("[INFO] [PRUEBAS] No se encontraron proyectos de prueba.")
        $findings.TestStatus = "NO_TESTS_FOUND"
    } else {
        $allTestsPassed = $true
        foreach ($testProj in $testProjects) {
            Write-Host "`n  📌 Ejecutando Suite: $($testProj.Name)" -ForegroundColor Cyan
            $testLogFile = Join-Path $Root "_audit_test_raw.log"
            
            $isExecutable = (Get-Content $testProj.FullName -Raw) -match '<OutputType>Exe</OutputType>'
            if ($isExecutable) {
                Write-Host "    [INFO] Proyecto ejecutable detectado. Usando 'dotnet run'." -ForegroundColor Gray
                & $dotnetExe run --project "$($testProj.FullName)" --no-build > $testLogFile 2>&1
            } else {
                & $dotnetExe test "$($testProj.FullName)" --no-build -v:normal > $testLogFile 2>&1
            }
            $rawTestOutput = Get-Content $testLogFile -Encoding UTF8 -ErrorAction SilentlyContinue
            Remove-Item $testLogFile -Force -ErrorAction SilentlyContinue

            # Usamos un regex más específico para detectar el resumen de fallo
            if ($rawTestOutput -match "Failed!.*, Total:.*, Passed:.*, Failed:.*") {
                $allTestsPassed = $false
                $findings.AllFindingsList.Add("[FAIL] [PRUEBAS] La suite '$($testProj.Name)' falló.")
                $findings.TestFailures.Add("Suite fallida: $($testProj.Name)")
                $rawTestOutput | ForEach-Object {
                    if ($_ -match "^\s*Failed!\s*-\s*|Exception|error|Stack Trace") {
                        $findings.TestFailures.Add("    $_")
                        Write-Host "    $_" -ForegroundColor Red
                    } elseif ($_ -match "^\s*Passed!\s*-\s*") {
                        Write-Host "    $_" -ForegroundColor Green
                    }
                }
            } else {
                Write-Host "    [✓] Suite completada sin fallos detectados." -ForegroundColor Green
            }
        }
        $findings.TestStatus = if ($allTestsPassed) { "PASS" } else { "FAIL" }
    }
}
Write-Host ""


# ==============================================================================
# 6. INFORME FINAL DE AUDITORÍA
# ==============================================================================
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host " 📋 INFORME FINAL DE AUDITORÍA 'ULTRA-CHISMOSA'" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host ""

# --- Métricas ---
Write-Host "📊 MÉTRICAS DEL CÓDIGO" -ForegroundColor Cyan
Write-Host "   ├── Archivos C#      : $($findings.Metrics.ArchivosCSharp)"
Write-Host "   └── Líneas de código : $($findings.Metrics.LineasDeCodigo)"
Write-Host ""

# --- Estado de Compilación ---
Write-Host "🛠️ ESTADO DE COMPILACIÓN: $($findings.BuildStatus)" -ForegroundColor $(if ($findings.BuildStatus -eq 'OK') {'Green'} else {'Red'})
if ($findings.BuildErrors.Count -gt 0) {
    $grouped = $findings.BuildErrors | Group-Object Archivo
    foreach ($group in $grouped) {
        Write-Host "   📄 ARCHIVO: $($group.Name)" -ForegroundColor Yellow
        foreach ($err in $group.Group) {
            Write-Host "      ├── Línea $($err.Linea): [$($err.Codigo)] $($err.Mensaje)" -ForegroundColor Red
        }
    }
}
Write-Host ""

# --- Estado de Pruebas ---
Write-Host "🧪 ESTADO DE PRUEBAS: $($findings.TestStatus)" -ForegroundColor $(if ($findings.TestStatus -eq 'PASS' -or $findings.TestStatus -eq 'NO_TESTS_FOUND') {'Green'} elseif ($findings.TestStatus -eq 'SKIPPED') {'Gray'} else {'Red'})
if ($findings.TestFailures.Count -gt 0) {
    $findings.TestFailures | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
}
Write-Host ""

# --- Hallazgos de Calidad y Arquitectura ---
Write-Host "🤔 HALLAZGOS DE CALIDAD Y ARQUITECTURA" -ForegroundColor Cyan
$totalSmells = $findings.UnimplementedStubs.Count + $findings.CodeTodos.Count + $findings.ArchFindings.Count
if ($totalSmells -eq 0) {    
    Write-Host "   [✓] ¡Excelente! No se encontraron hallazgos automáticos." -ForegroundColor Green
} else {
    if ($findings.UnimplementedStubs.Count -gt 0) {
        Write-Host "   - Endpoints/Stubs no implementados:" -ForegroundColor Yellow
        $findings.UnimplementedStubs | ForEach-Object { 
            $findingMsg = "[MEDIUM] [CALIDAD] NotImplementedException en '$($_.Path)' (Línea: $($_.LineNumber))"
            $findings.AllFindingsList.Add($findingMsg)
            Write-Host "     - $($_.Path) (Línea: $($_.LineNumber))" -ForegroundColor Gray 
        }
    }
    if ($findings.CodeTodos.Count -gt 0) {
        Write-Host "   - Tareas pendientes (TODO/FIXME):" -ForegroundColor Yellow
        $findings.CodeTodos | ForEach-Object { 
            $findingMsg = "[LOW] [CALIDAD] Comentario TODO/FIXME en '$($_.Path)' (Línea: $($_.LineNumber)): $($_.Line.Trim())"
            $findings.AllFindingsList.Add($findingMsg)
            Write-Host "     - $($_.Path) (Línea: $($_.LineNumber)): $($_.Line.Trim())" -ForegroundColor Gray 
        }
    }
    if ($findings.ArchFindings.Count -gt 0) {
        Write-Host "   - Problemas de arquitectura detectados:" -ForegroundColor Yellow
        $findings.ArchFindings | ForEach-Object { Write-Host "     - $_" -ForegroundColor Gray }
    }
}

# ==============================================================================
# 7. GENERACIÓN DE REPORTES
# ==============================================================================
Write-Host "`n>>> [FASE 7] Generando reportes de auditoría..." -ForegroundColor Yellow

$finalStatus = if ($findings.BuildStatus -ne 'OK' -or $findings.TestStatus -eq 'FAIL') { "FAIL" } else { "PASS" }

$reportObject = @{
    Timestamp = (Get-Date).ToString("o")
    Project = "ADSOLUSOL"
    Status = $finalStatus
    Metrics = $findings.Metrics
    Build = @{
        Status = $findings.BuildStatus
        Errors = $findings.BuildErrors
    }
    Tests = @{
        Status = $findings.TestStatus
        Failures = $findings.TestFailures
    }
    CodeQuality = @{
        Unimplemented = $findings.UnimplementedStubs
        Todos = $findings.CodeTodos
    }
    Architecture = @{
        Findings = $findings.ArchFindings
    }
    SummaryFindings = $findings.AllFindingsList
}

# --- Reporte JSON ---
$jsonReportPath = Join-Path $Root "audit_report_adsolusol.json"
try {
    $reportObject | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonReportPath -Encoding UTF8
    Write-Host "[✓] Reporte JSON generado en: $jsonReportPath" -ForegroundColor Green
} catch {
    Write-Host "[!] No se pudo escribir el reporte JSON: $($_.Exception.Message)" -ForegroundColor Red
}

# --- Reporte Markdown ---
$mdReportPath = Join-Path $Root "audit_report_adsolusol.md"
$mdContent = @"
# 📋 Reporte de Auditoría: ADSOLUSOL

*   **Fecha:** $(Get-Date)
*   **Resultado General:** **$($reportObject.Status)**

## 📊 Métricas

| Métrica          | Valor                               |
| ---------------- | ----------------------------------- |
| Archivos C#      | $($reportObject.Metrics.ArchivosCSharp) |
| Líneas de Código | $($reportObject.Metrics.LineasDeCodigo) |

## 🛠️ Compilación: $($reportObject.Build.Status)

## 🧪 Pruebas: $($reportObject.Tests.Status)

## 📜 Resumen de Hallazgos ($($reportObject.SummaryFindings.Count))

$($reportObject.SummaryFindings | ForEach-Object { "- $($_)" } | Out-String)

"@
try {
    $mdContent | Set-Content -Path $mdReportPath -Encoding UTF8
    Write-Host "[✓] Reporte Markdown generado en: $mdReportPath" -ForegroundColor Green
} catch {
    Write-Host "[!] No se pudo escribir el reporte Markdown: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host " FIN DE LA AUDITORÍA" -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta

# Finaliza con un código de error si hubo fallos críticos
if (-not $CI_MODE) {
    Write-Host ""
    Read-Host "Presiona ENTER para cerrar la auditoría"
}

if ($finalStatus -eq 'FAIL' -and $CI_MODE) {
    exit 1
}
