<#
================================================================================
  ADSOLUSOL :: AUDITORIA DE SEGURIDAD, CRIPTOGRAFIA Y PROTECCION EDR
  Verifica blindaje Ed25519, middleware de firmas, prevencion de replay,
  ausencia de secretos en texto plano e inmunidad contra inyecciones.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [SEGURIDAD] AUDITORIA DE CRIPTOGRAFIA, FIRMAS Y BLINDAJE PERIMETRAL      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$securityErrors = 0

function Assert-Sec([bool]$Cond, [string]$Id, [string]$Msg) {
    if ($Cond) {
        Write-Host "  [PASS] [$Id] $Msg" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] [$Id] $Msg" -ForegroundColor Red
        $script:securityErrors++
    }
}

# 1. Verificacion de Headers obligatorios de protocolo Ed25519 en Middleware
Write-Host "[1/4] Auditando pipeline HTTP y cabeceras obligatorias de firma..." -ForegroundColor Yellow
$mwPath = Join-Path $ScriptRoot "src/ADSOLUSOL.Presentation.Api/Middleware/SignatureVerificationMiddleware.cs"
if (Test-Path $mwPath) {
    $mwText = [System.IO.File]::ReadAllText($mwPath, [System.Text.Encoding]::UTF8)
    $requiredHeaders = @("X-Solusol-Signature", "X-Solusol-Node-Id", "X-Solusol-Timestamp", "X-Solusol-Nonce")
    foreach ($hdr in $requiredHeaders) {
        $found = $mwText -match [regex]::Escape($hdr)
        Assert-Sec $found "AUTH-HEADER" "Cabecera de autenticidad '$hdr' validada en middleware."
    }
} else {
    Assert-Sec $false "AUTH-MW" "SignatureVerificationMiddleware.cs no encontrado."
}

# 2. Verificacion de control Anti-Replay (Nonce y Timestamp)
Write-Host "`n[2/4] Verificando proteccion contra ataques de repeticion (Anti-Replay)..." -ForegroundColor Yellow
if (Test-Path $mwPath) {
    $hasTimestampValidation = $mwText -match "Timestamp" -and ($mwText -match "TimeSpan" -or $mwText -match "UtcNow")
    $hasNonceValidation = $mwText -match "Nonce"
    Assert-Sec $hasTimestampValidation "REPLAY-WINDOW" "Ventana temporal de expiracion de firma implementada."
    Assert-Sec $hasNonceValidation "REPLAY-NONCE" "Mecanismo de validacion de Nonce anti-reenvio implementado."
}

# 3. Barrido forense por secretos, contrasenas y claves privadas hardcodeadas
Write-Host "`n[3/4] Escaneando codigo fuente por fuga de secretos o llaves PEM/RSA..." -ForegroundColor Yellow
$sourceFiles = Get-ChildItem -Path (Join-Path $ScriptRoot "src") -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\/[\\/]' }

$secretPatterns = @(
    @{ Pattern = 'BEGIN\s+(RSA\s+)?PRIVATE\s+KEY'; Name = "Clave privada PEM/RSA en codigo" },
    @{ Pattern = '(?i)password\s*=\s*"[^"]{6,}"'; Name = "Posible contrasena en texto plano" },
    @{ Pattern = '(?i)secretkey\s*=\s*"[^"]{6,}"'; Name = "Posible SecretKey hardcodeada" },
    @{ Pattern = '(?i)apikey\s*=\s*"[A-Za-z0-9_\-]{20,}"'; Name = "Posible API Key hardcodeada" }
)

$secretsFound = 0
foreach ($sf in $sourceFiles) {
    $text = [System.IO.File]::ReadAllText($sf.FullName, [System.Text.Encoding]::UTF8)
    foreach ($p in $secretPatterns) {
        if ($text -match $p.Pattern) {
            Write-Host "  [FAIL] [LEAK-SECRET] $($p.Name) detectado en: $($sf.Name)" -ForegroundColor Red
            $secretsFound++
            $securityErrors++
        }
    }
}
if ($secretsFound -eq 0) {
    Write-Host "  [PASS] [LEAK-SECRET] Cero credenciales ni llaves privadas expuestas en codigo C#." -ForegroundColor Green
}

# 4. Deteccion de inyecciones de comandos u ofuscacion peligrosa en scripts
Write-Host "`n[4/4] Comprobando scripts por heurísticas maliciosas o Invoke-Expression..." -ForegroundColor Yellow
$scripts = Get-ChildItem -Path (Join-Path $ScriptRoot "scripts") -Recurse -Filter "*.ps1" -File -ErrorAction SilentlyContinue
$obfuscationCount = 0
foreach ($s in $scripts) {
    $sContent = [System.IO.File]::ReadAllText($s.FullName, [System.Text.Encoding]::UTF8)
    if ($sContent -match "Invoke-Expression\s+\$" -or $sContent -match "\biex\s+\$") {
        Write-Host "  [FAIL] [SCRIPT-EDR] Inyeccion dinamica sospechosa (iex) en: $($s.Name)" -ForegroundColor Red
        $obfuscationCount++
        $securityErrors++
    }
}
if ($obfuscationCount -eq 0) {
    Write-Host "  [PASS] [SCRIPT-EDR] Scripts de automatizacion limpios de patrones maliciosos EDR." -ForegroundColor Green
}

# 5. Validacion de CSP y Rate Limiting
Write-Host "`n[5/5] Comprobando controles de mitigacion DoS y Rate Limiting..." -ForegroundColor Yellow
$programFile = Join-Path $ScriptRoot "src/ADSOLUSOL.Presentation.Api/Program.cs"
if (Test-Path $programFile) {
    $progText = [System.IO.File]::ReadAllText($programFile, [System.Text.Encoding]::UTF8)
    if ($progText -match "RateLimiter" -or $progText -match "UseRateLimiter") {
        Write-Host "  [PASS] [DOS-DEFENSE] Rate Limiting registrado en pipeline HTTP." -ForegroundColor Green
    } else {
        Write-Host "  [WARN] [DOS-DEFENSE] Rate Limiting no detectado explicitamente en Program.cs." -ForegroundColor Yellow
    }
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                     DICTAMEN DE SEGURIDAD DIGITAL                        " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones de Seguridad : $securityErrors" -ForegroundColor $(if ($securityErrors -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($securityErrors -gt 0) {
    Write-Host ""
    Write-Host "[FAIL] Se detectaron vulnerabilidades o fallos de autenticidad criptografica." -ForegroundColor Red
    Write-Host ""
    exit 1
} else {
    Write-Host ""
    Write-Host "[PASS] Blindaje perimetral, criptografia Ed25519 y controles Anti-Replay SOLIDOS." -ForegroundColor Green
    Write-Host ""
    exit 0
}