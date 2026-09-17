﻿param(
    [string]$Root = (Get-Location).Path,
    [switch]$RunBuild,
    [switch]$RunRegression,
    [switch]$RunSmoke,
    [switch]$Deep,
    [switch]$NoPause
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AuditVersion = "1.0.0"
$StartedAt = Get-Date
$Root = [System.IO.Path]::GetFullPath($Root)
$AuditDir = Join-Path $Root "_audit"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$JsonReport = Join-Path $AuditDir "ADSOLUSOL-AUDIT-$Stamp.json"
$TxtReport  = Join-Path $AuditDir "ADSOLUSOL-AUDIT-$Stamp.txt"

$Findings = [System.Collections.Generic.List[object]]::new()
$script:FileLinesCache = [System.Collections.Generic.Dictionary[string, string[]]]::new()
$Stats = [ordered]@{
    FilesScanned = 0
    CSharpFiles = 0
    MarkdownFiles = 0
    JsonFiles = 0
    CsprojFiles = 0
    Critical = 0
    High = 0
    Medium = 0
    Low = 0
    Info = 0
}

$dotnetPath = "C:\Users\Radio 2027\Documents\Codex\tools\dotnet\dotnet.exe"
if (-not (Test-Path $dotnetPath)) {
    if ($env:ADSOLUSOL_DOTNET -and (Test-Path $env:ADSOLUSOL_DOTNET)) {
        $dotnetPath = $env:ADSOLUSOL_DOTNET
    } else {
        $dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue
        $dotnetPath = if ($dotnetCmd) { $dotnetCmd.Source } else { "dotnet" }
    }
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 78) -ForegroundColor DarkCyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 78) -ForegroundColor DarkCyan
}

function Add-Finding {
    param(
        [ValidateSet("CRITICAL","HIGH","MEDIUM","LOW","INFO")]
        [string]$Severity,
        [string]$Code,
        [string]$Category,
        [string]$Message,
        [string]$File = "",
        [int]$Line = 0,
        [string]$Evidence = ""
    )

    $item = [pscustomobject]@{
        Severity  = $Severity
        Code      = $Code
        Category  = $Category
        Message   = $Message
        File      = $File
        Line      = $Line
        Evidence  = $Evidence
        Timestamp = (Get-Date).ToString("o")
    }
    $Findings.Add($item) | Out-Null
    $Stats[$Severity]++

    $color = switch ($Severity) {
        "CRITICAL" { "Red" }
        "HIGH"     { "Magenta" }
        "MEDIUM"   { "Yellow" }
        "LOW"      { "DarkYellow" }
        default    { "Gray" }
    }

    $loc = if ($File) {
        if ($Line -gt 0) { " [$File`:$Line]" } else { " [$File]" }
    } else { "" }

    Write-Host ("[{0}] [{1}] {2}{3}" -f $Severity,$Code,$Message,$loc) -ForegroundColor $color
}

function Get-RelativePathSafe {
    param([string]$Path)
    try { return [System.IO.Path]::GetRelativePath($Root, $Path) }
    catch { return $Path }
}

function Is-ExcludedPath {
    param([string]$FullName)
    $p = $FullName.Replace('\','/').ToLowerInvariant()
    return (
        $p -match '\.git' -or
        $p -match '(^|/)(bin|obj|_audit|node_modules|coverage|testresults|artifacts)(/|$)' -or
        $p -match '\.deps\.json$' -or
        $p -match 'project\.assets\.json$'
    )
}

function Get-SourceFiles {
    param([string[]]$Extensions)
    Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            -not (Is-ExcludedPath $_.FullName) -and
            $Extensions -contains $_.Extension.ToLowerInvariant()
        }
}

function Read-LinesSafe {
    param([string]$Path)
    try { return Get-Content -LiteralPath $Path -ErrorAction Stop }
    catch {
        Add-Finding -Severity "LOW" -Code "ADS-IO-001" -Category "READ" `
            -Message "No se pudo leer un archivo durante la auditoría." `
            -File (Get-RelativePathSafe $Path) -Evidence $_.Exception.Message
        return @()
    }
}

function Search-Regex {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$Pattern,
        [string]$Severity,
        [string]$Code,
        [string]$Category,
        [string]$Message,
        [switch]$Redact
    )

    foreach ($f in $Files) {
        $lines = Read-LinesSafe $f.FullName
        for ($i=0; $i -lt $lines.Count; $i++) {
            $line = [string]$lines[$i]
            if ($line -match $Pattern) {
                $evidence = $line.Trim()
                if ($Redact) { $evidence = "[REDACTED MATCH]" }
                Add-Finding -Severity $Severity -Code $Code -Category $Category `
                    -Message $Message -File (Get-RelativePathSafe $f.FullName) `
                    -Line ($i+1) -Evidence $evidence
            }
        }
    }
}

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-ExternalCaptured {
    param(
        [string]$Title,
        [string]$Executable,
        [string[]]$Arguments
    )

    Write-Host ""
    Write-Host ">>> $Title" -ForegroundColor Cyan
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Executable
    foreach ($a in $Arguments) { [void]$psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Root
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    return [pscustomobject]@{
        ExitCode = $p.ExitCode
        StdOut = $stdout
        StdErr = $stderr
        Combined = ($stdout + "`n" + $stderr).Trim()
    }
}

function Normalize-Evidence {
    param([string]$Text, [int]$Max = 1400)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $t = $Text -replace "`0",""
    if ($t.Length -le $Max) { return $t.Trim() }
    return ($t.Substring(0,$Max) + " ...[TRUNCATED]").Trim()
}

Write-Section "ADSOLUSOL — AUDITORÍA ULTRA SUPERCHISMOSA"
Write-Host "Version : $AuditVersion"
Write-Host "Root    : $Root"
Write-Host "Inicio  : $StartedAt"
Write-Host ""
Write-Host "MODO: SOLO LECTURA SOBRE FUENTE. Únicamente escribe reportes en _audit/." -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    throw "Root inexistente: $Root"
}

# -----------------------------------------------------------------------------
# FASE 0 — IDENTIDAD DEL PROYECTO
# -----------------------------------------------------------------------------
Write-Section "FASE 0 — IDENTIDAD Y ALCANCE ADSOLUSOL"

$solution = Join-Path $Root "ADSOLUSOL.sln"
$srcDir = Join-Path $Root "src"

if (-not (Test-Path -LiteralPath $solution -PathType Leaf)) {
    Add-Finding -Severity "CRITICAL" -Code "ADS-SCOPE-001" -Category "SCOPE" `
        -Message "No se localizó ADSOLUSOL.sln en la raíz. Root posiblemente incorrecto." `
        -File "ADSOLUSOL.sln"
} else {
    Add-Finding -Severity "INFO" -Code "ADS-SCOPE-OK" -Category "SCOPE" `
        -Message "ADSOLUSOL.sln localizado." -File "ADSOLUSOL.sln"
}

if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) {
    Add-Finding -Severity "CRITICAL" -Code "ADS-SCOPE-002" -Category "SCOPE" `
        -Message "No existe la carpeta src/ esperada."
}

$expectedProjects = @(
    "src/ADSOLUSOL.Domain/ADSOLUSOL.Domain.csproj",
    "src/ADSOLUSOL.Application/ADSOLUSOL.Application.csproj",
    "src/ADSOLUSOL.Infrastructure/ADSOLUSOL.Infrastructure.csproj",
    "src/ADSOLUSOL.Motor/ADSOLUSOL.Motor.csproj",
    "src/ADSOLUSOL.Orchestrator/ADSOLUSOL.Orchestrator.csproj",
    "src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj",
    "src/ADSOLUSOL.Presentation.Cmd/ADSOLUSOL.Presentation.Cmd.csproj"
)

foreach ($rel in $expectedProjects) {
    $p = Join-Path $Root $rel
    if (Test-Path -LiteralPath $p -PathType Leaf) {
        Add-Finding -Severity "INFO" -Code "ADS-PROJ-OK" -Category "STRUCTURE" `
            -Message "Proyecto esperado localizado." -File $rel
    } else {
        Add-Finding -Severity "MEDIUM" -Code "ADS-PROJ-001" -Category "STRUCTURE" `
            -Message "Proyecto esperado no localizado." -File $rel
    }
}

# -----------------------------------------------------------------------------
# INVENTARIO
# -----------------------------------------------------------------------------
Write-Section "FASE 1 — INVENTARIO"

$allFiles = Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\/[\\/]' -and $_.Extension -ne '.json' }

$csFiles = @($allFiles | Where-Object Extension -eq ".cs")
$mdFiles = @($allFiles | Where-Object Extension -eq ".md")
$jsonFiles = @($allFiles | Where-Object Extension -eq ".json")
$csprojFiles = @($allFiles | Where-Object Extension -eq ".csproj")
$configFiles = @($allFiles | Where-Object { $_.Extension -in @(".json",".config",".props",".targets",".xml",".yml",".yaml") })
$psFiles = @($allFiles | Where-Object Extension -eq ".ps1")

$Stats.FilesScanned = $allFiles.Count
$Stats.CSharpFiles = $csFiles.Count
$Stats.MarkdownFiles = $mdFiles.Count
$Stats.JsonFiles = $jsonFiles.Count
$Stats.CsprojFiles = $csprojFiles.Count

Add-Finding -Severity "INFO" -Code "ADS-INV-001" -Category "INVENTORY" `
    -Message "Inventario completado." `
    -Evidence ("files={0}; cs={1}; md={2}; json={3}; csproj={4}" -f `
        $Stats.FilesScanned,$Stats.CSharpFiles,$Stats.MarkdownFiles,$Stats.JsonFiles,$Stats.CsprojFiles)

# -----------------------------------------------------------------------------
# DOCUMENTACIÓN BASE
# -----------------------------------------------------------------------------
Write-Section "FASE 2 — DOCUMENTACIÓN Y CONTRATOS"

$importantDocs = @(
    "README.md",
    "REQUIREMENTS.md",
    "ROADMAP.md",
    "MAP.md",
    "docs/ADSOLUSOL.md",
    "docs/CONTRACTS.md",
    "docs/contracts/CONTRACTS.md",
    "docs/contracts/MARKETING-API.md",
    "docs/security/INTEGRITY.md",
    "docs/architecture/MAP.md"
)

foreach ($rel in $importantDocs) {
    $p = Join-Path $Root $rel
    if (Test-Path -LiteralPath $p -PathType Leaf) {
        $size = (Get-Item -LiteralPath $p).Length
        if ($size -eq 0) {
            Add-Finding -Severity "MEDIUM" -Code "ADS-DOC-EMPTY" -Category "DOCUMENTATION" `
                -Message "Documento presente pero vacío." -File $rel
        } else {
            Add-Finding -Severity "INFO" -Code "ADS-DOC-OK" -Category "DOCUMENTATION" `
                -Message "Documento localizado." -File $rel
        }
    }
}

Search-Regex -Files $mdFiles -Pattern '\bIMPLEMENTADO\b|\bIMPLEMENTED\b' -Severity "INFO" `
    -Code "ADS-DOC-STATE" -Category "DOCUMENTATION" `
    -Message "Afirmación documental de implementación localizada; requiere evidencia ejecutable para certificación."

Search-Regex -Files $mdFiles -Pattern '\bCERTIFIED\b|\bCERTIFICADO\b|\bSEALED\b' -Severity "LOW" `
    -Code "ADS-DOC-CERT" -Category "DOCUMENTATION" `
    -Message "Afirmación de certificación/sellado localizada. Verificar que exista evidencia real asociada."

# -----------------------------------------------------------------------------
# SECRETOS / CREDENCIALES
# -----------------------------------------------------------------------------
Write-Section "FASE 3 — SECRETOS Y CREDENCIALES"

$secretFiles = @($csFiles + $configFiles + $psFiles)
$secretPatterns = @(
    '(?i)(password|passwd|pwd)\s*[:=]\s*["''][^"'']{4,}',
    '(?i)(api[_-]?key|apikey|secret|token)\s*[:=]\s*["''][^"'']{8,}',
    '-----BEGIN (RSA |EC |OPENSSH |)?PRIVATE KEY-----',
    '(?i)connectionstring[s]?\s*[:=].*(password|pwd)\s*=',
    '(?i)bearer\s+[A-Za-z0-9\-\._~\+\/]+=*'
)
foreach ($pat in $secretPatterns) {
    Search-Regex -Files $secretFiles -Pattern $pat -Severity "CRITICAL" `
        -Code "ADS-SECRET-001" -Category "SECRETS" `
        -Message "Posible secreto o credencial literal en archivo fuente/configuración." -Redact
}

Search-Regex -Files $configFiles -Pattern '(?i)"Api"\s*:\s*\{|"Key"\s*:\s*"[^"]+"' `
    -Severity "INFO" -Code "ADS-APIKEY-CONFIG" -Category "AUTH" `
    -Message "Configuración relacionada con API key localizada. Confirmar que no contenga valor secreto persistido."

# -----------------------------------------------------------------------------
# BUILD / ESTRUCTURA C#
# -----------------------------------------------------------------------------
Write-Section "FASE 4 — COMPILACIÓN Y ESTRUCTURA C#"

Search-Regex -Files $csFiles -Pattern '^\s*namespace\s+[^;]+;\s*$' -Severity "INFO" `
    -Code "ADS-CS-FILESCOPED" -Category "CSHARP" `
    -Message "Namespace file-scoped localizado."

Search-Regex -Files $csFiles -Pattern 'NotImplementedException|throw\s+new\s+NotSupportedException' `
    -Severity "MEDIUM" -Code "ADS-STUB-001" -Category "IMPLEMENTATION" `
    -Message "Stub/operación no implementada localizada."

Search-Regex -Files $csFiles -Pattern '\bTODO\b|\bFIXME\b|\bHACK\b' `
    -Severity "LOW" -Code "ADS-TODO-001" -Category "MAINTENANCE" `
    -Message "Marcador TODO/FIXME/HACK localizado."

Search-Regex -Files $csFiles -Pattern 'Console\.Write(Line)?\(' `
    -Severity "INFO" -Code "ADS-CONSOLE-001" -Category "LOGGING" `
    -Message "Escritura directa a consola localizada."

# -----------------------------------------------------------------------------
# ARQUITECTURA / DEPENDENCIAS
# -----------------------------------------------------------------------------
Write-Section "FASE 5 — ARQUITECTURA POR CAPAS"

$layerRules = @(
    @{ Name="Domain->Infrastructure"; Folder="src/ADSOLUSOL.Domain"; Pattern='using\s+ADSOLUSOL\.Infrastructure'; Severity="HIGH" },
    @{ Name="Domain->Presentation";   Folder="src/ADSOLUSOL.Domain"; Pattern='using\s+ADSOLUSOL\.Presentation'; Severity="HIGH" },
    @{ Name="Application->Presentation"; Folder="src/ADSOLUSOL.Application"; Pattern='using\s+ADSOLUSOL\.Presentation'; Severity="HIGH" }
)

foreach ($rule in $layerRules) {
    $folder = Join-Path $Root $rule.Folder
    if (Test-Path -LiteralPath $folder) {
        $files = @(Get-ChildItem -LiteralPath $folder -Filter *.cs -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { -not (Is-ExcludedPath $_.FullName) })
        Search-Regex -Files $files -Pattern $rule.Pattern -Severity $rule.Severity `
            -Code "ADS-ARCH-001" -Category "ARCHITECTURE" `
            -Message ("Dependencia de capa no deseada: " + $rule.Name)
    }
}

# -----------------------------------------------------------------------------
# TENANT / MULTITENANCY
# -----------------------------------------------------------------------------
Write-Section "FASE 6 — MULTI-TENANT Y AISLAMIENTO"

Search-Regex -Files $csFiles -Pattern '(?i)TenantId\s*=\s*["''][^"'']+["'']' `
    -Severity "MEDIUM" -Code "ADS-TENANT-HARDCODE" -Category "TENANT" `
    -Message "TenantId literal localizado. Verificar si es fixture/test o configuración autorizada."

Search-Regex -Files $csFiles -Pattern '(?i)(Request|body|payload).*(TenantId|tenant_id)|(TenantId|tenant_id).*(Request|body|payload)' `
    -Severity "MEDIUM" -Code "ADS-TENANT-CLIENT" -Category "TENANT" `
    -Message "Posible tenant proveniente del cliente. Confirmar derivación desde identidad/configuración confiable."

Search-Regex -Files $csFiles -Pattern 'GetCampaignsAsync\s*\(\s*[^,\)]*tenant|GetCampaignAsync\s*\(\s*[^,\)]*tenant' `
    -Severity "INFO" -Code "ADS-TENANT-QUERY" -Category "TENANT" `
    -Message "Consulta de campañas con tenant explícito localizada."

Search-Regex -Files $csFiles -Pattern 'string\.IsNullOrWhiteSpace\s*\(\s*tenant|tenant(Id)?\s*==\s*""' `
    -Severity "INFO" -Code "ADS-TENANT-FAILCLOSED" -Category "TENANT" `
    -Message "Validación de tenant vacío localizada."

# -----------------------------------------------------------------------------
# AUTH TEMPORAL / X-API-KEY
# -----------------------------------------------------------------------------
Write-Section "FASE 7 — AUTENTICACIÓN TEMPORAL Y CORE"

Search-Regex -Files $csFiles -Pattern 'X-Api-Key' `
    -Severity "MEDIUM" -Code "ADS-AUTH-TEMP-001" -Category "AUTH" `
    -Message "X-Api-Key sigue presente. Válido solo como mecanismo temporal/local, no como identidad SOLUSOL definitiva."

Search-Regex -Files $csFiles -Pattern 'X-Core-Signature|X-Solusol-Signature|X-Solusol-Node-Id|X-Solusol-Timestamp|X-Solusol-Nonce' `
    -Severity "INFO" -Code "ADS-AUTH-HEADER" -Category "AUTH" `
    -Message "Header de autenticación/identidad SOLUSOL localizado."

# -----------------------------------------------------------------------------
# CRIPTOGRAFÍA: RSA PROHIBIDO EN PUENTE SOLUSOL_AUTH_V1
# -----------------------------------------------------------------------------
Write-Section "FASE 8 — CRIPTOGRAFÍA SOLUSOL_AUTH_V1"

Search-Regex -Files $csFiles -Pattern '\bRSA\.Create\b|RSASignaturePadding|ImportSubjectPublicKeyInfo' `
    -Severity "HIGH" -Code "ADS-CRYPTO-RSA" -Category "CRYPTO" `
    -Message "RSA localizado en flujo ADS. Si corresponde a CORE/SIC, es incompatible con SOLUSOL_AUTH_V1 Ed25519."

Search-Regex -Files $csFiles -Pattern 'Ed25519|NSec\.Cryptography|BouncyCastle' `
    -Severity "INFO" -Code "ADS-CRYPTO-ED25519" -Category "CRYPTO" `
    -Message "Uso/referencia Ed25519 localizado."

# Detecta separadores literales erróneos en canonical payload.
Search-Regex -Files $csFiles -Pattern 'SOLUSOL_AUTH_V1\s*\|' `
    -Severity "HIGH" -Code "ADS-AUTH-CANON-001" -Category "CRYPTO" `
    -Message "Posible canonical payload con separador literal '|'. SOLUSOL_AUTH_V1 exige concatenación directa de bytes sin delimitadores literales."

Search-Regex -Files $csFiles -Pattern 'SOLUSOL_AUTH_V1' `
    -Severity "INFO" -Code "ADS-AUTH-V1" -Category "CRYPTO" `
    -Message "Referencia a SOLUSOL_AUTH_V1 localizada."

Search-Regex -Files $csFiles -Pattern 'SHA256\.HashData|SHA256\.Create|HashAlgorithmName\.SHA256' `
    -Severity "LOW" -Code "ADS-CRYPTO-SHA256" -Category "CRYPTO" `
    -Message "SHA-256 localizado. Confirmar que no se use como prehash del mensaje Ed25519 de SOLUSOL_AUTH_V1."

# NodeID, timestamp, nonce, context.
foreach ($item in @(
    @{P='\bNodeId\b|\bNodeID\b'; C='ADS-AUTH-NODEID'; M='NodeID localizado.'},
    @{P='\bTimestamp\b|DateTimeOffset\.UtcNow|DateTime\.UtcNow'; C='ADS-AUTH-TIME'; M='Timestamp/frescura localizado.'},
    @{P='\bNonce\b|nonce'; C='ADS-AUTH-NONCE'; M='Nonce localizado.'},
    @{P='\bContext\b|context'; C='ADS-AUTH-CONTEXT'; M='Context localizado.'}
)) {
    Search-Regex -Files $csFiles -Pattern $item.P -Severity "INFO" -Code $item.C `
        -Category "CRYPTO" -Message $item.M
}

# Anti replay.
Search-Regex -Files $csFiles -Pattern '(?i)replay|noncecache|ConcurrentDictionary.*nonce|MemoryCache.*nonce' `
    -Severity "INFO" -Code "ADS-AUTH-REPLAY" -Category "CRYPTO" `
    -Message "Mecanismo/referencia anti-replay localizada."

# Ventana temporal ±5s.
Search-Regex -Files $csFiles -Pattern 'TotalSeconds\s*[<>]=?\s*5|FromSeconds\s*\(\s*5\s*\)|TimeSpan\.FromSeconds\s*\(\s*5\s*\)' `
    -Severity "INFO" -Code "ADS-AUTH-SKEW" -Category "CRYPTO" `
    -Message "Referencia a ventana temporal de 5 segundos localizada."

# -----------------------------------------------------------------------------
# DI / BOOTSTRAP
# -----------------------------------------------------------------------------
Write-Section "FASE 9 — DEPENDENCY INJECTION / BOOTSTRAP"

$programCandidates = @($csFiles | Where-Object Name -eq "Program.cs")
foreach ($program in $programCandidates) {
    $content = (Read-LinesSafe $program.FullName) -join "`n"

    foreach ($service in @("CoreSignatureVerifier","MarketingBrainClient","CampaignService")) {
        $ctorUse = ($csFiles | ForEach-Object {
            try {
                if ((Get-Content -LiteralPath $_.FullName -Raw) -match [regex]::Escape($service)) { $_ }
            } catch {}
        }).Count -gt 0

        if ($ctorUse -and $content -notmatch ("Add(Scoped|Singleton|Transient).*" + [regex]::Escape($service))) {
            Add-Finding -Severity "HIGH" -Code "ADS-DI-001" -Category "DI" `
                -Message "Servicio usado pero no se encontró registro explícito en Program.cs: $service" `
                -File (Get-RelativePathSafe $program.FullName)
        } elseif ($content -match ("Add(Scoped|Singleton|Transient).*" + [regex]::Escape($service))) {
            Add-Finding -Severity "INFO" -Code "ADS-DI-OK" -Category "DI" `
                -Message "Servicio registrado en DI: $service" `
                -File (Get-RelativePathSafe $program.FullName)
        }
    }
}

# -----------------------------------------------------------------------------
# API / ENDPOINTS
# -----------------------------------------------------------------------------
Write-Section "FASE 10 — API Y ENDPOINTS ADS"

$expectedApiPatterns = @(
    @{Pattern='/api/marketing/adsolusol/campaigns'; Name='Campaign collection'},
    @{Pattern='/api/marketing/adsolusol/campaigns/\{id\}'; Name='Campaign item'},
    @{Pattern='/toggle'; Name='Toggle campaign'},
    @{Pattern='/click'; Name='Click'},
    @{Pattern='/impression'; Name='Impression'},
    @{Pattern='/api/health'; Name='Health'},
    @{Pattern='/api/health/storage'; Name='Storage health'}
)

$apiFiles = @($csFiles | Where-Object { $_.FullName -match 'Presentation\.Api' })
$apiText = ""
foreach ($f in $apiFiles) {
    try { $apiText += "`n" + (Get-Content -LiteralPath $f.FullName -Raw) } catch {}
}

foreach ($ep in $expectedApiPatterns) {
    if ($apiText -match $ep.Pattern) {
        Add-Finding -Severity "INFO" -Code "ADS-API-PRESENT" -Category "API" `
            -Message ("Endpoint/ruta localizada: " + $ep.Name)
    } else {
        Add-Finding -Severity "LOW" -Code "ADS-API-MISSING" -Category "API" `
            -Message ("Endpoint/ruta esperada no localizada: " + $ep.Name)
    }
}

Search-Regex -Files $apiFiles -Pattern 'Status503ServiceUnavailable|StatusCode\s*\(\s*503|NotImplementedException' `
    -Severity "MEDIUM" -Code "ADS-API-STUB-503" -Category "API" `
    -Message "Endpoint o flujo devuelve 503/NotImplemented. Confirmar si es fail-closed intencional o implementación pendiente."

Search-Regex -Files $apiFiles -Pattern 'return\s+Ok\s*\(\s*new\s*\{\s*status\s*=\s*"SUCCESS"' `
    -Severity "LOW" -Code "ADS-API-SUCCESS" -Category "API" `
    -Message "Respuesta SUCCESS localizada. Confirmar que exista operación persistida/verificada antes del éxito."

# -----------------------------------------------------------------------------
# MARKETING BRAIN / SIC BRIDGE
# -----------------------------------------------------------------------------
Write-Section "FASE 11 — PUENTE ADSOLUSOL → SIC"

$brainFiles = @($csFiles | Where-Object { $_.Name -match 'MarketingBrainClient|Sic|Telemetry' -or $_.FullName -match 'MarketingBrain' })

Search-Regex -Files $brainFiles -Pattern '127\.0\.0\.1:8080|localhost:8080' `
    -Severity "INFO" -Code "ADS-SIC-ENDPOINT" -Category "SIC_BRIDGE" `
    -Message "Endpoint local de SIC localizado."

Search-Regex -Files $brainFiles -Pattern 'Task\.FromResult\s*\(\s*false\s*\)|SIC integration is unavailable|NOT_CONFIGURED|UNAVAILABLE' `
    -Severity "MEDIUM" -Code "ADS-SIC-STUB" -Category "SIC_BRIDGE" `
    -Message "Puente SIC aún contiene estado explícito de indisponibilidad/no configurado."

Search-Regex -Files $brainFiles -Pattern 'HttpClient|PostAsync|PostAsJsonAsync|SendAsync' `
    -Severity "INFO" -Code "ADS-SIC-HTTP" -Category "SIC_BRIDGE" `
    -Message "Cliente HTTP del puente SIC localizado."

Search-Regex -Files $brainFiles -Pattern 'ADS_CLICK|ADS_IMPRESSION|CAMPAIGN_|SignalDTO|Telemetry' `
    -Severity "INFO" -Code "ADS-SIC-SIGNAL" -Category "SIC_BRIDGE" `
    -Message "Señal/telemetría ADS→SIC localizada."

Search-Regex -Files $brainFiles -Pattern '"http://[^"]+"' `
    -Severity "LOW" -Code "ADS-SIC-HTTP-PLAIN" -Category "TRANSPORT" `
    -Message "URL HTTP literal localizada. Aceptable solo para loopback/local si el contrato lo permite."

# -----------------------------------------------------------------------------
# ZERO SYNTHETIC
# -----------------------------------------------------------------------------
Write-Section "FASE 12 — ZERO SYNTHETIC"

Search-Regex -Files $csFiles -Pattern '(?i)(mock|fake|dummy|sample|demo).*(click|impression|ctr|cpm|cpc|spend|campaign)' `
    -Severity "MEDIUM" -Code "ADS-ZS-001" -Category "ZERO_SYNTHETIC" `
    -Message "Posible dato publicitario simulado/ficticio localizado en código productivo. Verificar contexto."

Search-Regex -Files $csFiles -Pattern '(?i)(click|impression|ctr|cpm|cpc|spend).*(Random|Next\()|(Random|Next\().*(click|impression|ctr|cpm|cpc|spend)' `
    -Severity "HIGH" -Code "ADS-ZS-002" -Category "ZERO_SYNTHETIC" `
    -Message "Métrica publicitaria aparentemente generada aleatoriamente."

Search-Regex -Files $csFiles -Pattern '"DISCONNECTED"|"NO_DATA"|"UNVERIFIED"|"UNAVAILABLE"|"NOT_CONFIGURED"' `
    -Severity "INFO" -Code "ADS-ZS-STATE" -Category "ZERO_SYNTHETIC" `
    -Message "Estado explícito Zero-Synthetic localizado."

# -----------------------------------------------------------------------------
# CAMPAIGNS / MONEY / BUDGET
# -----------------------------------------------------------------------------
Write-Section "FASE 13 — CAMPAIGNS, MONEY Y PRESUPUESTO"

Search-Regex -Files $csFiles -Pattern '\bdouble\b.*(Budget|Spend|Price|Cost|CPM|CPC)|\bfloat\b.*(Budget|Spend|Price|Cost|CPM|CPC)' `
    -Severity "HIGH" -Code "ADS-MONEY-001" -Category "MONEY" `
    -Message "Uso de float/double en cantidad monetaria publicitaria. Preferir decimal/representación exacta."

Search-Regex -Files $csFiles -Pattern '\bdecimal\b.*(Budget|Spend|Price|Cost|CPM|CPC)|(Budget|Spend|Price|Cost|CPM|CPC).*\bdecimal\b' `
    -Severity "INFO" -Code "ADS-MONEY-DECIMAL" -Category "MONEY" `
    -Message "Uso de decimal en modelo monetario localizado."

Search-Regex -Files $csFiles -Pattern 'Guid\.NewGuid\(\)' `
    -Severity "INFO" -Code "ADS-ID-GUID" -Category "DOMAIN" `
    -Message "Generación de identificador GUID localizada."

Search-Regex -Files $csFiles -Pattern '(Budget|budget)\s*[<]=?\s*0|(Budget|budget)\s*==\s*0' `
    -Severity "INFO" -Code "ADS-BUDGET-VALIDATION" -Category "DOMAIN" `
    -Message "Validación de presupuesto no positivo localizada."

# -----------------------------------------------------------------------------
# SQLITE / PERSISTENCIA
# -----------------------------------------------------------------------------
Write-Section "FASE 14 — SQLITE Y PERSISTENCIA"

$storageFiles = @($csFiles | Where-Object { $_.FullName -match 'Persistence|Repository|DbContext|Storage' })

Search-Regex -Files $storageFiles -Pattern 'Microsoft\.Data\.Sqlite|SqliteConnection' `
    -Severity "INFO" -Code "ADS-SQLITE-001" -Category "STORAGE" `
    -Message "Persistencia SQLite localizada."

Search-Regex -Files $storageFiles -Pattern 'PRAGMA\s+journal_mode\s*=\s*WAL|journal_mode=WAL' `
    -Severity "INFO" -Code "ADS-SQLITE-WAL" -Category "STORAGE" `
    -Message "Configuración SQLite WAL localizada."

Search-Regex -Files $storageFiles -Pattern '\+\s*["'']\s*(SELECT|INSERT|UPDATE|DELETE)|\$\s*"[^"]*(SELECT|INSERT|UPDATE|DELETE)' `
    -Severity "HIGH" -Code "ADS-SQL-001" -Category "SQL" `
    -Message "Posible construcción dinámica de SQL por concatenación/interpolación."

Search-Regex -Files $storageFiles -Pattern 'BEGIN\s+TRANSACTION|BeginTransaction|Commit|Rollback' `
    -Severity "INFO" -Code "ADS-SQL-TX" -Category "STORAGE" `
    -Message "Manejo transaccional localizado."

# -----------------------------------------------------------------------------
# HTTP / RED / SSRF
# -----------------------------------------------------------------------------
Write-Section "FASE 15 — RED, HTTP Y SSRF"

Search-Regex -Files $csFiles -Pattern '0\.0\.0\.0|\[\:\:\]' `
    -Severity "HIGH" -Code "ADS-NET-001" -Category "NETWORK" `
    -Message "Binding abierto localizado. Verificar exposición real."

Search-Regex -Files $csFiles -Pattern 'http://127\.0\.0\.1|http://localhost' `
    -Severity "INFO" -Code "ADS-NET-LOCALHTTP" -Category "NETWORK" `
    -Message "HTTP loopback localizado."

Search-Regex -Files $csFiles -Pattern 'new\s+HttpClient\s*\(' `
    -Severity "LOW" -Code "ADS-HTTPCLIENT-001" -Category "NETWORK" `
    -Message "Instanciación directa de HttpClient localizada. Verificar lifetime/DI."

Search-Regex -Files $csFiles -Pattern 'AllowAutoRedirect\s*=\s*true|DangerousAcceptAnyServerCertificateValidator|ServerCertificateCustomValidationCallback.*true' `
    -Severity "CRITICAL" -Code "ADS-TLS-001" -Category "TLS" `
    -Message "Configuración insegura de TLS/redirect localizada."

# -----------------------------------------------------------------------------
# LOGGING / DATOS SENSIBLES
# -----------------------------------------------------------------------------
Write-Section "FASE 16 — LOGGING Y DATOS SENSIBLES"

Search-Regex -Files $csFiles -Pattern '(?i)Log(Information|Warning|Error|Debug|Trace)\s*\([^;\n]*(ApiKey|Signature|PrivateKey|Nonce|Authorization|Token)' `
    -Severity "HIGH" -Code "ADS-LOG-SECRET" -Category "LOGGING" `
    -Message "Posible material sensible incluido en log."

# -----------------------------------------------------------------------------
# EXCEPCIONES / FAIL-CLOSED
# -----------------------------------------------------------------------------
Write-Section "FASE 17 — ERROR HANDLING / FAIL-CLOSED"

Search-Regex -Files $csFiles -Pattern 'catch\s*\{\s*\}' `
    -Severity "MEDIUM" -Code "ADS-ERR-EMPTYCATCH" -Category "ERROR_HANDLING" `
    -Message "Catch vacío localizado."

Search-Regex -Files $csFiles -Pattern 'catch\s*\([^)]+\)\s*\{\s*return\s+(true|Ok\()' `
    -Severity "HIGH" -Code "ADS-ERR-FAILOPEN" -Category "ERROR_HANDLING" `
    -Message "Posible fail-open: excepción seguida de éxito."

# -----------------------------------------------------------------------------
# TESTS
# -----------------------------------------------------------------------------
Write-Section "FASE 18 — TESTS Y REGRESIONES"

$testFiles = @($csFiles | Where-Object { $_.FullName -match '\\tests\\|RegressionTests|Tests' })
if ($testFiles.Count -eq 0) {
    Add-Finding -Severity "MEDIUM" -Code "ADS-TEST-001" -Category "TESTS" `
        -Message "No se localizaron archivos C# de pruebas/regresión."
} else {
    Add-Finding -Severity "INFO" -Code "ADS-TEST-COUNT" -Category "TESTS" `
        -Message "Archivos de prueba/regresión localizados." -Evidence ("count=" + $testFiles.Count)
}

Search-Regex -Files $testFiles -Pattern 'Ed25519|SOLUSOL_AUTH_V1|Replay|Nonce|Timestamp|Tenant|Campaign|SQLite' `
    -Severity "INFO" -Code "ADS-TEST-COVERAGE" -Category "TESTS" `
    -Message "Cobertura temática relevante localizada en pruebas."

# -----------------------------------------------------------------------------
# DEEP MODE
# -----------------------------------------------------------------------------
if ($Deep) {
    Write-Section "FASE 19 — DEEP MODE"

    Search-Regex -Files $csFiles -Pattern 'Task\.Delay|Thread\.Sleep' `
        -Severity "LOW" -Code "ADS-DEEP-SLEEP" -Category "DEEP" `
        -Message "Espera artificial localizada."

    Search-Regex -Files $csFiles -Pattern 'Environment\.Exit|Process\.Kill|Process\.Start' `
        -Severity "MEDIUM" -Code "ADS-DEEP-PROCESS" -Category "DEEP" `
        -Message "Control/ejecución de procesos externos localizado."

    Search-Regex -Files $csFiles -Pattern 'File\.Delete|Directory\.Delete|File\.Move|Directory\.Move' `
        -Severity "MEDIUM" -Code "ADS-DEEP-FS" -Category "DEEP" `
        -Message "Operación mutante de filesystem localizada."

    Search-Regex -Files $csFiles -Pattern 'DateTime\.Now' `
        -Severity "LOW" -Code "ADS-DEEP-LOCALTIME" -Category "DEEP" `
        -Message "DateTime.Now localizado. Verificar uso de UTC en contratos distribuidos."

    Search-Regex -Files $csFiles -Pattern 'Random\(' `
        -Severity "LOW" -Code "ADS-DEEP-RANDOM" -Category "DEEP" `
        -Message "System.Random localizado. No usar para material criptográfico."
}

# -----------------------------------------------------------------------------
# BUILD REAL
# -----------------------------------------------------------------------------
$BuildResult = $null
if ($RunBuild) {
    Write-Section "FASE 20 — DOTNET BUILD REAL"

        if (-not (Test-Path $dotnetPath -ErrorAction SilentlyContinue) -and -not (Test-CommandExists $dotnetPath)) {
        Add-Finding -Severity "CRITICAL" -Code "ADS-BUILD-NODOTNET" -Category "BUILD" `
            -Message "dotnet no está disponible en PATH."
    } elseif (-not (Test-Path -LiteralPath $solution -PathType Leaf)) {
        Add-Finding -Severity "CRITICAL" -Code "ADS-BUILD-NOSLN" -Category "BUILD" `
            -Message "No puede ejecutarse build: ADSOLUSOL.sln no existe."
    } else {
        $BuildResult = Invoke-ExternalCaptured -Title "dotnet build ADSOLUSOL.sln" `
                -Executable $dotnetPath -Arguments @("build","ADSOLUSOL.sln","--nologo")

        if ($BuildResult.ExitCode -eq 0) {
            Add-Finding -Severity "INFO" -Code "ADS-BUILD-PASS" -Category "BUILD" `
                -Message "BUILD PASS real confirmado por dotnet build." `
                -Evidence (Normalize-Evidence $BuildResult.Combined)
        } else {
            Add-Finding -Severity "CRITICAL" -Code "ADS-BUILD-FAIL" -Category "BUILD" `
                -Message "BUILD FAILURE real." `
                -Evidence (Normalize-Evidence $BuildResult.Combined 3500)
        }
    }
} else {
    Add-Finding -Severity "INFO" -Code "ADS-BUILD-SKIPPED" -Category "BUILD" `
        -Message "Build no ejecutado. Use -RunBuild para exigir evidencia real."
}

# -----------------------------------------------------------------------------
# REGRESSION EXECUTABLE
# -----------------------------------------------------------------------------
if ($RunRegression) {
    Write-Section "FASE 21 — REGRESSION SUITE"

        if (-not (Test-Path $dotnetPath -ErrorAction SilentlyContinue) -and -not (Test-CommandExists $dotnetPath)) {
        Add-Finding -Severity "CRITICAL" -Code "ADS-REG-NODOTNET" -Category "TESTS" `
            -Message "dotnet no está disponible."
    } else {
        $regProject = Join-Path $Root "tests/ADSOLUSOL.RegressionTests"
        if (Test-Path -LiteralPath $regProject) {
            $reg = Invoke-ExternalCaptured -Title "ADSOLUSOL RegressionTests" `
                    -Executable $dotnetPath -Arguments @("run","--project","tests/ADSOLUSOL.RegressionTests")
            if ($reg.ExitCode -eq 0) {
                Add-Finding -Severity "INFO" -Code "ADS-REG-PASS" -Category "TESTS" `
                    -Message "RegressionTests PASS." -Evidence (Normalize-Evidence $reg.Combined)
            } else {
                Add-Finding -Severity "HIGH" -Code "ADS-REG-FAIL" -Category "TESTS" `
                    -Message "RegressionTests FAIL." -Evidence (Normalize-Evidence $reg.Combined 3000)
            }
        } else {
            Add-Finding -Severity "MEDIUM" -Code "ADS-REG-MISSING" -Category "TESTS" `
                -Message "No se encontró tests/ADSOLUSOL.RegressionTests."
        }
    }
}

# -----------------------------------------------------------------------------
# SMOKE TEST
# -----------------------------------------------------------------------------
if ($RunSmoke) {
    Write-Section "FASE 22 — SMOKE TEST"
    $smoke = Join-Path $Root "scripts/smoke_test.ps1"
    if (Test-Path -LiteralPath $smoke -PathType Leaf) {
        $pwshExe = if (Test-CommandExists "pwsh") { "pwsh" } else { "powershell" }
        $sm = Invoke-ExternalCaptured -Title "smoke_test.ps1" -Executable $pwshExe `
                -Arguments @("-NoProfile","-ExecutionPolicy","Bypass","-File",$smoke,"-DotnetPath",$dotnetPath)
        if ($sm.ExitCode -eq 0) {
            Add-Finding -Severity "INFO" -Code "ADS-SMOKE-PASS" -Category "TESTS" `
                -Message "Smoke test PASS." -Evidence (Normalize-Evidence $sm.Combined)
        } else {
            Add-Finding -Severity "HIGH" -Code "ADS-SMOKE-FAIL" -Category "TESTS" `
                -Message "Smoke test FAIL." -Evidence (Normalize-Evidence $sm.Combined 3000)
        }
    } else {
        Add-Finding -Severity "LOW" -Code "ADS-SMOKE-MISSING" -Category "TESTS" `
            -Message "scripts/smoke_test.ps1 no localizado."
    }
}

# -----------------------------------------------------------------------------
# GIT
# -----------------------------------------------------------------------------
Write-Section "FASE 23 — GIT STATUS"

if (Test-CommandExists "git") {
    $gitDir = Join-Path $Root ".git"
    if (Test-Path -LiteralPath $gitDir) {
        $git = Invoke-ExternalCaptured -Title "git status --porcelain" -Executable "git" `
            -Arguments @("status","--porcelain")
        if ([string]::IsNullOrWhiteSpace($git.StdOut)) {
            Add-Finding -Severity "INFO" -Code "ADS-GIT-CLEAN" -Category "GIT" `
                -Message "Working tree limpio."
        } else {
            Add-Finding -Severity "INFO" -Code "ADS-GIT-DIRTY" -Category "GIT" `
                -Message "Working tree contiene cambios." `
                -Evidence (Normalize-Evidence $git.StdOut 2500)
        }
    }
}

# -----------------------------------------------------------------------------
# INVARIANTES DE INTEGRACIÓN SIC/ADS
# -----------------------------------------------------------------------------
Write-Section "FASE 24 — INVARIANTES SIC ↔ ADSOLUSOL"

$allText = ""
foreach ($f in @($csFiles + $mdFiles)) {
    try { $allText += "`n" + (Get-Content -LiteralPath $f.FullName -Raw) } catch {}
}

$integrationChecks = @(
    @{ Regex='SOLUSOL_AUTH_V1'; Severity='HIGH'; Code='ADS-INT-AUTH'; Message='Contrato SOLUSOL_AUTH_V1 no localizado.' },
    @{ Regex='Ed25519'; Severity='HIGH'; Code='ADS-INT-ED'; Message='Ed25519 no localizado.' },
    @{ Regex='NodeId|NodeID'; Severity='MEDIUM'; Code='ADS-INT-NODE'; Message='NodeID no localizado.' },
    @{ Regex='Nonce'; Severity='MEDIUM'; Code='ADS-INT-NONCE'; Message='Nonce no localizado.' },
    @{ Regex='Timestamp'; Severity='MEDIUM'; Code='ADS-INT-TIME'; Message='Timestamp no localizado.' },
    @{ Regex='Context'; Severity='LOW'; Code='ADS-INT-CONTEXT'; Message='Context no localizado.' },
    @{ Regex='TenantId|tenant_id'; Severity='HIGH'; Code='ADS-INT-TENANT'; Message='Tenant no localizado.' },
    @{ Regex='MarketingBrainClient'; Severity='MEDIUM'; Code='ADS-INT-BRAIN'; Message='MarketingBrainClient no localizado.' }
)

foreach ($c in $integrationChecks) {
    if ($allText -notmatch $c.Regex) {
        Add-Finding -Severity $c.Severity -Code $c.Code -Category "SIC_INTEGRATION" `
            -Message $c.Message
    } else {
        Add-Finding -Severity "INFO" -Code ($c.Code + "-PRESENT") -Category "SIC_INTEGRATION" `
            -Message ("Presencia confirmada: " + $c.Regex)
    }
}

# -----------------------------------------------------------------------------
# RESUMEN / REPORTES
# -----------------------------------------------------------------------------
Write-Section "RESUMEN"

$EndedAt = Get-Date
$Duration = $EndedAt - $StartedAt

$Gate = if ($Stats.Critical -gt 0) {
    "FAIL"
} elseif ($Stats.High -gt 0) {
    "REVIEW"
} else {
    "PASS"
}

$report = [ordered]@{
    Product = "ADSOLUSOL"
    Audit = "ULTRA SUPERCHISMOSO"
    AuditVersion = $AuditVersion
    StartedAt = $StartedAt.ToString("o")
    EndedAt = $EndedAt.ToString("o")
    DurationSeconds = [math]::Round($Duration.TotalSeconds, 3)
    Root = $Root
    Mode = @{
        RunBuild = [bool]$RunBuild
        RunRegression = [bool]$RunRegression
        RunSmoke = [bool]$RunSmoke
        Deep = [bool]$Deep
    }
    Gate = $Gate
    Stats = $Stats
    Findings = $Findings
}

New-Item -ItemType Directory -Path $AuditDir -Force | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonReport -Encoding UTF8

$txt = [System.Collections.Generic.List[string]]::new()
$txt.Add("=" * 78)
$txt.Add("ADSOLUSOL - AUDITORÍA ULTRA SUPERCHISMOSA")
$txt.Add("=" * 78)
$txt.Add("Version: $AuditVersion")
$txt.Add("Root: $Root")
$txt.Add("Gate: $Gate")
$txt.Add("")
$txt.Add(("CRITICAL : {0}" -f $Stats.Critical))
$txt.Add(("HIGH     : {0}" -f $Stats.High))
$txt.Add(("MEDIUM   : {0}" -f $Stats.Medium))
$txt.Add(("LOW      : {0}" -f $Stats.Low))
$txt.Add(("INFO     : {0}" -f $Stats.Info))
$txt.Add("")
$txt.Add("NOTA: PASS significa que no se detectaron CRITICAL/HIGH por este auditor.")
$txt.Add("No equivale por sí solo a certificación de producción.")
$txt.Add("")

$orderedFindings = $Findings | Sort-Object `
    @{Expression={ switch ($_.Severity) { "CRITICAL"{0} "HIGH"{1} "MEDIUM"{2} "LOW"{3} default{4} } }}, `
    Code, File, Line

foreach ($f in $orderedFindings) {
    $loc = if ($f.File) {
        if ($f.Line -gt 0) { "$($f.File):$($f.Line)" } else { $f.File }
    } else { "" }
    $txt.Add(("[{0}] [{1}] {2}" -f $f.Severity,$f.Code,$f.Message))
    if ($loc) { $txt.Add(("  Archivo: {0}" -f $loc)) }
    if ($f.Evidence) { $txt.Add(("  Evidencia: {0}" -f (Normalize-Evidence $f.Evidence 1200))) }
    $txt.Add("")
}

$txt | Set-Content -LiteralPath $TxtReport -Encoding UTF8

Write-Host ""
Write-Host ("Gate     : {0}" -f $Gate) -ForegroundColor $(if($Gate -eq "FAIL"){"Red"}elseif($Gate -eq "REVIEW"){"Yellow"}else{"Green"})
Write-Host ("CRITICAL : {0}" -f $Stats.Critical)
Write-Host ("HIGH     : {0}" -f $Stats.High)
Write-Host ("MEDIUM   : {0}" -f $Stats.Medium)
Write-Host ("LOW      : {0}" -f $Stats.Low)
Write-Host ("INFO     : {0}" -f $Stats.Info)
Write-Host ""
Write-Host "JSON: $JsonReport"
Write-Host "TXT : $TxtReport"

Write-Host ""
Write-Host "TOP HALLAZGOS:" -ForegroundColor Cyan
$top = @($orderedFindings | Where-Object Severity -in @("CRITICAL","HIGH","MEDIUM") | Select-Object -First 50)
if ($top.Count -eq 0) {
    Write-Host "Sin hallazgos CRITICAL/HIGH/MEDIUM." -ForegroundColor Green
} else {
    foreach ($f in $top) {
        $loc = if ($f.File) { " [$($f.File):$($f.Line)]" } else { "" }
        Write-Host ("[{0}] [{1}] {2}{3}" -f $f.Severity,$f.Code,$f.Message,$loc)
    }
}

if (-not $NoPause) {
    Write-Host ""
    Read-Host "Presiona ENTER para cerrar la auditoría"
}

if ($Stats.Critical -gt 0) { exit 2 }
if ($Stats.High -gt 0) { exit 1 }
exit 0
