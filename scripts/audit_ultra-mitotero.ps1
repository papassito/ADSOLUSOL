<#
================================================================================
 ADSOLUSOL :: MOTOR DE AUDITORÍA PERICIAL Y ESCANEO PROFUNDO v1.0
 "Ultra-Mitotero, declarando con precisión la verdad del ecosistema ADS"
================================================================================

 PRINCIPIOS:
 - NOT_DETECTED != DOES_NOT_EXIST
 - STRING_FOUND != IMPLEMENTED
 - COMPILATION_FAIL != SYNTAX_ERROR
 - DOCUMENT_FOUND != ACTIVE_INTEGRATION
 - DECLARED != EXECUTED

 SOLO LECTURA:
 Este script NO modifica archivos de código ni bases de datos.
================================================================================
#>

param(
    [string]$Root = ".",
    [bool]$RequireBaselineAtRoot = $false
)

$ErrorActionPreference = "Continue"
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot = if ($scriptDir) { Split-Path -Parent $scriptDir } else { (Resolve-Path $Root).Path }
Set-Location $RepoRoot

# ==============================================================================
# CONFIGURACIÓN DE BASELINE
# ==============================================================================
$BaselineDocs = @(
    "README.md",
    "docs\contracts\MARKETING-API.md",
    "docs\architecture\MOTOR.md",
    "docs\STRUCTURE.md",
    "docs\LIBRARY.md"
)

$ExpectedProjects = @(
    "src\ADSOLUSOL.Domain\ADSOLUSOL.Domain.csproj",
    "src\ADSOLUSOL.Application\ADSOLUSOL.Application.csproj",
    "src\ADSOLUSOL.Infrastructure\ADSOLUSOL.Infrastructure.csproj",
    "src\ADSOLUSOL.Motor\ADSOLUSOL.Motor.csproj",
    "src\ADSOLUSOL.Orchestrator\ADSOLUSOL.Orchestrator.csproj",
    "src\ADSOLUSOL.Presentation.Api\ADSOLUSOL.Presentation.Api.csproj",
    "src\ADSOLUSOL.Presentation.Cmd\ADSOLUSOL.Presentation.Cmd.csproj"
)

$RequiredContracts = @(
    "GET /api/marketing/seo",
    "GET /api/marketing/adsolusol",
    "POST /api/marketing/adsolusol/campaigns",
    "POST /api/marketing/adsolusol/campaigns/:id/toggle",
    "POST /api/marketing/adsolusol/campaigns/:id/click",
    "POST /api/marketing/adsolusol/campaigns/:id/impression"
)

$Findings = @()
$PassedChecks = 0

# ==============================================================================
# AUXILIARES DE REPORTE Y FORMATO
# ==============================================================================
function Add-Finding {
    param(
        [string]$Code,
        [string]$Category,
        [string]$Description,
        [ValidateSet("INFO","LOW","MEDIUM","HIGH","CRITICAL")]
        [string]$Severity,
        [string]$EvidenceScope = "",
        [string]$Evidence = ""
    )
    $script:Findings += [PSCustomObject]@{
        Code          = $Code
        Category      = $Category
        Description   = $Description
        Severity      = $Severity
        EvidenceScope = $EvidenceScope
        Evidence      = $Evidence
        Timestamp     = (Get-Date).ToString("o")
    }
}

function Add-Pass {
    param([string]$Message)
    $script:PassedChecks++
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Show-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Show-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }
function Show-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

# ==============================================================================
# CABECERA
# ==============================================================================
Clear-Host
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host " 🔬 ADSOLUSOL :: MOTOR DE AUDITORÍA PERICIAL Y ESCANEO PROFUNDO v1.0" -ForegroundColor Magenta
Write-Host "    'Analizador Ultra-Mitotero para ecosistema .NET 8'" -ForegroundColor DarkMagenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Directorio de Trabajo: $RepoRoot" -ForegroundColor Gray

# ==============================================================================
# FASE 0 — LOCALIZAR DOTNET SDK PORTABLE
# ==============================================================================
Write-Host ""
Show-Info "[FASE 0] Verificando SDK de .NET..."
$dotnetPath = $env:ADSOLUSOL_DOTNET
if (-not $dotnetPath -or -not (Test-Path -LiteralPath $dotnetPath)) {
    $dotnetPath = (Get-Command dotnet -ErrorAction SilentlyContinue).Source
}

if (-not $dotnetPath) {
    Add-Finding -Code "ADS-ENV-001" -Category "DOTNET_MISSING" -Description "No se detectó un ejecutable .NET en el entorno actual." -Severity "CRITICAL"
    Show-Fail "No se localizó un SDK de .NET. Cancelando fases de compilación."
} else {
    Add-Pass "SDK de .NET encontrado: $dotnetPath"
}

# ==============================================================================
# RECOLECCIÓN DE ARCHIVOS
# ==============================================================================
$AllFiles = Get-ChildItem -Path $RepoRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch '[\\/](\.git|bin|obj|\.vs|TestResults|coverage)[\\/]' -and
        $_.Name -notmatch '\.deps\.json$' -and $_.Name -notmatch 'project\.assets\.json$'
    }
$CsFiles = @($AllFiles | Where-Object { $_.Extension -eq ".cs" })
$TotalLOC = 0
foreach ($file in $CsFiles) {
    try { $TotalLOC += (Get-Content $file.FullName -ErrorAction SilentlyContinue).Count } catch {}
}

# ==============================================================================
# FASE 1 — BASELINE DOCUMENTAL Y NORMAS DE ESTRUCTURA
# ==============================================================================
Write-Host ""
Show-Info "[FASE 1] Verificando baseline documental..."
foreach ($doc in $BaselineDocs) {
    $path = Join-Path $RepoRoot $doc
    if (Test-Path -LiteralPath $path) {
        Add-Pass "Baseline localizado: $doc"
    } else {
        Add-Finding `
            -Code "ADS-DOC-001" `
            -Category "MISSING_BASELINE_DOC" `
            -Description "El documento obligatorio '$doc' no está en la ruta especificada." `
            -Severity "HIGH" `
            -EvidenceScope "docs"
        Show-Fail "Falta documento baseline: $doc"
    }
}

# ==============================================================================
# FASE 2 — ARQUITECTURA DE PROYECTOS (.csproj)
# ==============================================================================
Write-Host ""
Show-Info "[FASE 2] Verificando integridad de proyectos de la solución..."
foreach ($proj in $ExpectedProjects) {
    $path = Join-Path $RepoRoot $proj
    if (Test-Path -LiteralPath $path) {
        Add-Pass "Proyecto de la arquitectura detectado: $proj"
    } else {
        Add-Finding `
            -Code "ADS-ARCH-001" `
            -Category "MISSING_PROJECT" `
            -Description "El componente de la arquitectura '$proj' no fue encontrado." `
            -Severity "CRITICAL" `
            -EvidenceScope "src"
        Show-Fail "Componente ausente: $proj"
    }
}

# ==============================================================================
# FASE 3 — COBERTURA DE CONTRATOS (C# vs MARKETING-API.md)
# ==============================================================================
Write-Host ""
Show-Info "[FASE 3] Inspeccionando cobertura de API (Contrato vs Realidad C#)..."
$codigoCompleto = if ($CsFiles) {
    [string]::Join("`r`n", (Get-Content -LiteralPath $CsFiles.FullName -Raw -ErrorAction SilentlyContinue))
} else { "" }

foreach ($contract in $RequiredContracts) {
    # Normalizar ruta del contrato para buscar en atributos C# (Route)
    $cleanPath = $contract.Split(' ')[1].Replace(':id', '{id}').Replace('/api', '')
    $existe = $codigoCompleto -match [regex]::Escape($cleanPath)
    
    if ($existe) {
        # Verificar si devuelve indisponibilidad o está implementado de verdad
        if ($contract -match "click|impression|toggle") {
            $metodoBuscado = "class " + ($cleanPath.Split('/')[-1])
            $fakeCheck = $codigoCompleto -match "503" -or $codigoCompleto -match "NotImplementedException"
            if ($fakeCheck) {
                Add-Finding `
                    -Code "ADS-API-002" `
                    -Category "UNIMPLEMENTED_STUB" `
                    -Description "El endpoint '$contract' existe en el contrato y se declara en código, pero su ejecución real devuelve un 503 o lanza NotImplementedException." `
                    -Severity "MEDIUM" `
                    -EvidenceScope "Controllers" `
                    -Evidence $contract
                Show-Warn "Endpoint simulado/deshabilitado (503): $contract"
            } else {
                Add-Pass "Endpoint operativo detectado: $contract"
            }
        } else {
            Add-Pass "Endpoint de consulta mapeado: $contract"
        }
    } else {
        Add-Finding `
            -Code "ADS-API-001" `
            -Category "CONTRACT_BREACH" `
            -Description "El endpoint '$contract' requerido por MARKETING-API.md no está definido en ninguna clase de C#." `
            -Severity "HIGH" `
            -EvidenceScope "Controllers"
        Show-Fail "Endpoint documentado pero NO implementado en C#: $contract"
    }
}

# ==============================================================================
# FASE 4 — VERIFICACIÓN DE SEGURIDAD (CORE & SIC INTEGRATION)
# ==============================================================================
Write-Host ""
Show-Info "[FASE 4] Escaneando integración criptográfica y seguridad..."

# ¿Usamos X-Api-Key estático o hay trazas de seguridad criptográfica de firmas?
$tieneCriptografia = $codigoCompleto -match "Cryptography" -or $codigoCompleto -match "SHA256" -or $codigoCompleto -match "ECDsa"
$tieneValidacionFirmas = $codigoCompleto -match "Signature" -and $codigoCompleto -match "Verification"

if ($codigoCompleto -match "X-Api-Key") {
    if (-not $tieneValidacionFirmas) {
        Add-Finding `
            -Code "ADS-SEC-001" `
            -Category "STATIC_AUTH" `
            -Description "La seguridad de la API depende exclusivamente de la cabecera 'X-Api-Key' estática. No se detectan validaciones dinámicas basadas en firmas criptográficas de CORE." `
            -Severity "HIGH" `
            -EvidenceScope "ADSOLUSOL.Presentation.Api"
        Show-Warn "Seguridad local protegida solo por API-Key estático. Integración CORE/SIC ausente en runtime."
    } else {
        Add-Pass "Se encontraron firmas de seguridad o trazas de validación en el código."
    }
}

# ==============================================================================
# FASE 5 — ESTADO DE COMPILACIÓN (GATES REALES)
# ==============================================================================
Write-Host ""
Show-Info "[FASE 5] Compilando la solución con .NET SDK..."
$buildOK = $false
if ($dotnetPath) {
    try {
        $buildOutput = & $dotnetPath build (Join-Path $RepoRoot "ADSOLUSOL.sln") -c Debug 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            $buildOK = $true
            Add-Pass "Compilación de la solución exitosa (.NET 8)."
        } else {
            Add-Finding `
                -Code "ADS-BUILD-001" `
                -Category "BUILD_FAILURE" `
                -Description "La compilación de la solución falló." `
                -Severity "CRITICAL" `
                -EvidenceScope "dotnet build" `
                -Evidence ($buildOutput | Out-String)
            Show-Fail "La compilación falló con código de salida: $exitCode"
        }
    } catch {
        Show-Fail "Error crítico al intentar invocar el comando build: $_"
    }
}

# ==============================================================================
# MÉTRICAS Y RESUMEN
# ==============================================================================
$Warnings = @($Findings | Where-Object { $_.Severity -in @("LOW", "MEDIUM") }).Count
$HighErrors = @($Findings | Where-Object { $_.Severity -eq "HIGH" }).Count
$CriticalErrors = @($Findings | Where-Object { $_.Severity -eq "CRITICAL" }).Count
$Informational = @($Findings | Where-Object { $_.Severity -eq "INFO" }).Count
$BlockingFindings = $HighErrors + $CriticalErrors

$Status = if ($BlockingFindings -gt 0) { "FAIL" } elseif ($Warnings -gt 0) { "PASS_WITH_WARNINGS" } else { "PASS" }

# Generación del reporte en formato estructurado JSON
$Report = [PSCustomObject]@{
    Timestamp = (Get-Date).ToString("o")
    Status    = $Status
    Metrics   = [PSCustomObject]@{
        ArchivosEscaneados = $AllFiles.Count
        ArchivosCSharp     = $CsFiles.Count
        LineasDeCodigo     = $TotalLOC
        CheckpointsOk      = $PassedChecks
        Advertencias       = $Warnings
        ErroresGraves      = $HighErrors
        BloqueosCriticos   = $CriticalErrors
    }
    Findings  = $Findings
}

$ReportPath = Join-Path $RepoRoot "audit_report_adsolusol.json"
$Report | ConvertTo-Json -Depth 10 | Set-Content -Path $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "                 RESUMEN DE AUDITORÍA ADSOLUSOL" -ForegroundColor Magenta
Write-Host "=========================================================================="
Write-Host " Total Archivos Escaneados     : $($AllFiles.Count)"
Write-Host " Total Archivos C#             : $($CsFiles.Count)"
Write-Host " Líneas de código analizadas   : $TotalLOC"
Write-Host " Comprobaciones Correctas      : $PassedChecks"
Write-Host " Advertencias (Medium/Low)     : $Warnings"
Write-Host " Errores Graves / Críticos     : $BlockingFindings"
Write-Host " Estado de Compilación         : $(if ($buildOK) { "SÍ" } else { "NO" })"
Write-Host " Reporte Técnico Guardado En   : $ReportPath" -ForegroundColor Green
Write-Host "=========================================================================="

if ($BlockingFindings -gt 0) {
    Write-Host " Veredicto: CIRCUITO BLOQUEADO POR AUSENCIA DE INTEGRACIÓN CORE/SIC REAL" -ForegroundColor Red
    exit 1
} else {
    Write-Host " Veredicto: COMPILACIÓN Y ESTRUCTURA BASELINE CORRECTAS" -ForegroundColor Green
    exit 0
}
