<#
================================================================================
  ADSOLUSOL - SUITE FORENSE Y DE AUDITORÍA PROFUNDA (EDICIÓN ULTRA-CHISMOSA)
  Classification: MISSION-CRITICAL / FORENSIC INSPECTION
  Target: Integridad Estructural, Onion Architecture, Criptografía y .NET 8
================================================================================
#>

[CmdletBinding()]
param (
    [string]$RootPath = "",
    [switch]$ReportJson = $true
)

$ErrorActionPreference = "Continue"

# ------------------------------------------------------------------------------
# BANNER Y PRESENTACIÓN
# ------------------------------------------------------------------------------
Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🔬 ADSOLUSOL :: MOTOR DE AUDITORÍA PERICIAL Y ESCANEO PROFUNDO (v3.1)" -ForegroundColor Cyan
Write-Host "    'Inspección pericial de contratos, Onion Architecture, Ed25519 y .NET 8'" -ForegroundColor DarkCyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

if ([string]::IsNullOrWhiteSpace($RootPath)) {
    if (Test-Path "ADSOLUSOL.sln") {
        $RootPath = (Get-Location).Path
    } elseif (Test-Path "..\ADSOLUSOL.sln") {
        $RootPath = (Resolve-Path "..").Path
    } else {
        $RootPath = (Get-Location).Path
    }
}
$ResolvedRoot = (Resolve-Path $RootPath).Path

# ------------------------------------------------------------------------------
# BASELINE Y MATRICES NORMATIVAS
# ------------------------------------------------------------------------------
$AuthoritativeProjects = @(
    "src/ADSOLUSOL.Domain",
    "src/ADSOLUSOL.Application",
    "src/ADSOLUSOL.Infrastructure",
    "src/ADSOLUSOL.Presentation.Api",
    "src/ADSOLUSOL.Presentation.Desktop",
    "src/ADSOLUSOL.Presentation.Web"
)

$NormativeDocs = @(
    "README.md", "docs/MANIFEST.md", "docs/EXPEDIENTE_CLINICO_MAESTRO.md", "DOCUMENTATION_SEAL.json"
)

$MandatorySecurityHeaders = @(
    "X-Solusol-Node-Id", "X-Solusol-Timestamp", "X-Solusol-Nonce", "X-Solusol-Signature"
)

$BannedFilesOrFolders = @(
    ".DS_Store", "Thumbs.db", "*.tmp",
    "*_old.*", "*_copy.*", "backup", "temp"
)

$AuditResults = [ordered]@{
    Timestamp          = (Get-Date).ToString("o")
    Status             = "PASS"
    Metrics            = [ordered]@{
        TotalFilesScanned = 0
        TotalLinesOfCode  = 0
        PassedChecks     = 0
        Warnings         = 0
        CriticalErrors   = 0
    }
    ChismeReport       = @()
}

function Log-Step([string]$Phase, [string]$Message, [string]$Level = "INFO") {
    $Color = switch ($Level) {
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "FAIL"  { "Red" }
        "CHISME"{ "Magenta" }
        Default { "Cyan" }
    }
    Write-Host "[$Level] [$Phase] $Message" -ForegroundColor $Color
}

function Add-Chisme([string]$Code, [string]$Category, [string]$Description, [string]$Severity) {
    $AuditResults.ChismeReport += [pscustomobject]@{
        Code        = $Code
        Category    = $Category
        Description = $Description
        Severity    = $Severity
        Timestamp   = (Get-Date).ToString("o")
    }
    if ($Severity -eq "CRITICAL" -or $Severity -eq "HIGH") {
        $AuditResults.Metrics.CriticalErrors++
        $AuditResults.Status = "FAIL"
    } elseif ($Severity -eq "MEDIUM" -or $Severity -eq "LOW") {
        $AuditResults.Metrics.Warnings++
    }
}

# ==============================================================================
# FASE 0: AUDITORÍA DE ENTORNO Y MITOTERO DE GIT
# ==============================================================================
Log-Step "FASE 0" "Escaneando estado del entorno y rastros de Git..." "INFO"

if (Get-Command "git" -ErrorAction SilentlyContinue) {
    Push-Location $RootPath
    $GitStatus = git status --porcelain 2>&1
    if ($GitStatus) {
        Log-Step "GIT" "Se encontraron archivos no guardados o basura en el Git Working Tree!" "WARN"
        Add-Mitote "MITOTE-GIT-001" "GIT_DIRTY" "El repositorio tiene cambios sin commit o archivos untracked." "MEDIUM"
    } else {
        Log-Step "GIT" "Working tree de Git completamente limpio." "OK"
        $AuditResults.Metrics.PassedChecks++
    }
    Pop-Location
} else {
    Log-Step "GIT" "Git no está en el PATH. No podemos fiscalizar commits." "WARN"
}

# ==============================================================================
# FASE 1: DESENTIERRO DE ARCHIVOS FANTASMA, DUPES Y BASURA
# ==============================================================================
Log-Step "FASE 1" "Iniciando escaneo de basura, archivos duplicados y carpetas anidadas..." "INFO"

# 1.1 Buscar archivos prohibidos/basura
foreach ($Pattern in $BannedFilesOrFolders) {
    $Junk = Get-ChildItem -Path $RootPath -Recurse -Filter $Pattern -ErrorAction SilentlyContinue
    foreach ($Item in $Junk) {
        Log-Step "BASURA" "Archivo/Carpeta fuera de norma hallado: $($Item.FullName)" "CHISME"
        Add-Chisme "ADS-JUNK-001" "UNAUTHORIZED_FILE" "Archivo o basura detectada: $($Item.Name)" "LOW"
    }
}

# 1.2 Verificar los Documentos Sagrados
foreach ($Doc in $NormativeDocs) {
    $DocPath = Join-Path -Path $RootPath -ChildPath $Doc
    if (Test-Path $DocPath) {
        Log-Step "NORMATIVA" "Documento baseline presente: $Doc" "OK"
        $AuditResults.Metrics.PassedChecks++
    } else {
        Log-Step "NORMATIVA" "Falta el documento sagrado: $Doc" "FAIL"
        Add-Chisme "ADS-ERR-001" "MISSING_DOC" "Documento normativo ausente: $Doc" "CRITICAL"
    }
}

# 1.3 Verificar Proyectos Autorizados (.NET y Web)
foreach ($Proj in $AuthoritativeProjects) {
    $ProjPath = Join-Path -Path $RootPath -ChildPath $Proj
    if (Test-Path $ProjPath) {
        Log-Step "ARQUITECTURA" "Capa arquitectónica confirmada: $Proj" "OK"
        $AuditResults.Metrics.PassedChecks++
    } else {
        Log-Step "ARQUITECTURA" "Capa arquitectónica ausente: $Proj" "FAIL"
        Add-Chisme "ADS-ERR-002" "MISSING_PROJECT" "Proyecto arquitectónico ausente: $Proj" "HIGH"
    }
}

# ==============================================================================
# FASE 2: INSPECCIÓN FORENSE DE CODIFICACIÓN (BOM, SALTOS DE LÍNEA, ARCHIVOS VACÍOS)
# ==============================================================================
Log-Step "FASE 2" "Revisando codificación byte por byte (BOM, CRLF/LF, vacíos)..." "INFO"

$AllFiles = Get-ChildItem -Path $RootPath -Recurse -File -Exclude .git, bin, assets
$AuditResults.Metrics.TotalFilesScanned = $AllFiles.Count

foreach ($File in $AllFiles) {
    # Archivos de 0 Bytes
    if ($File.Length -eq 0) {
        Log-Step "FORENSE" "Archivo fantasma de 0 Bytes detectado: $($File.Name)" "CHISME"
        Add-Chisme "ADS-EMPTY-001" "ZERO_BYTE_FILE" "El archivo $($File.FullName) está totalmente vacío." "MEDIUM"
        continue
    }

    # Detección de BOM
    try {
        $b = [System.IO.File]::ReadAllBytes($File.FullName)
        if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
            Log-Step "ENCODING" "BOM detectado en: $($File.Name)" "WARN"
            Add-Chisme "ADS-WARN-001" "BOM_DETECTED" "El archivo $($File.Name) tiene BOM UTF-8." "MEDIUM"
        }
    } catch {}

    # Conteo de líneas de código si es .cs o .tsx
    if ($File.Extension -in @(".cs", ".tsx", ".ts")) {
        $Lines = (Get-Content -Path $File.FullName).Count
        $AuditResults.Metrics.TotalLinesOfCode += $Lines
    }
}

# ==============================================================================
# FASE 3: INSPECCIÓN DE CÓDIGO C# (MIDDLEWARE, CRYPTO Y TELEMETRÍA)
# ==============================================================================
Log-Step "FASE 3" "Escrutando el código C# por contratos duros (.NET 8, Ed25519, Telemetría)..." "INFO"

$MwFile = Join-Path $RootPath "src/ADSOLUSOL.Presentation.Api/Middleware/SignatureVerificationMiddleware.cs"
if (Test-Path $MwFile) {
    $mwCode = Get-Content -Path $MwFile -Raw
    foreach ($hdr in $MandatorySecurityHeaders) {
        if ($mwCode -match $hdr) {
            Log-Step "SEGURIDAD" "Encabezado Ed25519 verificado en pipeline: $hdr" "OK"
            $AuditResults.Metrics.PassedChecks++
        } else {
            Log-Step "SEGURIDAD" "Falta encabezado obligatorio en middleware: $hdr" "FAIL"
            Add-Chisme "ADS-SEC-001" "MISSING_HEADER" "Header Ed25519 faltante: $hdr" "HIGH"
        }
    }
} else {
    Log-Step "SEGURIDAD" "SignatureVerificationMiddleware.cs no encontrado." "FAIL"
    Add-Chisme "ADS-SEC-002" "NO_SIGNATURE_MW" "Middleware de firma Ed25519 ausente." "CRITICAL"
}

# ==============================================================================
# FASE 4: AUDITORÍA DE PERSISTENCIA Y SUITE DE REGRESIÓN
# ==============================================================================
Log-Step "FASE 4" "Verificando suites de pruebas y regresiones de negocio..." "INFO"

$RegTestProj = Join-Path $RootPath "tests/ADSOLUSOL.RegressionTests/ADSOLUSOL.RegressionTests.csproj"
if (Test-Path $RegTestProj) {
    Log-Step "REGRESION" "Proyecto de pruebas de regresión localizado: ADSOLUSOL.RegressionTests" "OK"
    $AuditResults.Metrics.PassedChecks++
} else {
    Log-Step "REGRESION" "Proyecto de regresión ausente." "FAIL"
    Add-Chisme "ADS-TEST-001" "MISSING_TEST_PROJECT" "Falta ADSOLUSOL.RegressionTests" "CRITICAL"
}

# ==============================================================================
# FASE 5: COMPILACIÓN Y TOOLCHAIN DE .NET 8
# ==============================================================================
Log-Step "FASE 5" "Verificando compilación con dotnet build (Release)..." "INFO"

$SlnFile = Join-Path $RootPath "ADSOLUSOL.sln"
if (Test-Path $SlnFile) {
    & dotnet build $SlnFile -c Release --no-restore -p:IgnoreMissingWorkloads=true -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false -v:quiet /nologo 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Log-Step "COMPILADOR" "Compilación .NET 8 limpia en Release!" "OK"
        $AuditResults.Metrics.PassedChecks++
    } else {
        Log-Step "COMPILADOR" "Fallo en compilación dotnet build!" "FAIL"
        Add-Chisme "ADS-ERR-003" "BUILD_FAIL" "La solución ADSOLUSOL.sln no compila limpiamente." "CRITICAL"
    }
}

# ==============================================================================
# FASE 6: RESUMEN EJECUTIVO Y EMISIÓN DE REPORTE JSON
# ==============================================================================
Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "                   RESUMEN PERICIAL ULTRA-MITOTERO" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Archivos Escaneados    : $($AuditResults.Metrics.TotalFilesScanned)" -ForegroundColor White
Write-Host " Líneas de Código (LOC) : $($AuditResults.Metrics.TotalLinesOfCode)" -ForegroundColor White
Write-Host " Pruebas Aprobadas      : $($AuditResults.Metrics.PassedChecks)" -ForegroundColor Green
Write-Host " Advertencias / Chismes : $($AuditResults.Metrics.Warnings)" -ForegroundColor Yellow
Write-Host " Errores Críticos       : $($AuditResults.Metrics.CriticalErrors)" -ForegroundColor Red
Write-Host " Estado Global          : $($AuditResults.Status)" -ForegroundColor $(if ($AuditResults.Status -eq "PASS") { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($ReportJson) {
    $ReportFile = Join-Path $RootPath "audit_report_ultra.json"
    $AuditResults | ConvertTo-Json -Depth 6 | Out-File -FilePath $ReportFile -Encoding utf8
    Log-Step "REPORTE" "Expediente JSON ultra-detallado generado en: $ReportFile" "OK"
}

Write-Host ""
Write-Host "[ PRESIONE CUALQUIER TECLA PARA CONTINUAR Y CONSERVAR LA CONSOLA ABIERTA ]" -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")