<#
================================================================================
  ADSOLUSOL DIAGNOSTIC SUITE :: VERIFICADOR FORENSE Y AUDITOR DE SALUD DIGITAL
  Ejecución directa sin bloqueo:
  powershell -ExecutionPolicy Bypass -File .\Verificar-Errores.ps1
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Path = ".",
    [switch]$Fix
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

$RootPath = (Resolve-Path $Path).Path
Set-Location $RootPath

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   ADSOLUSOL (ADS) :: ESCANER INTEGRAL FORENSE Y DE ERRORES      " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Directorio objetivo: $RootPath`n" -ForegroundColor DarkGray

$Global:TotalErrores = 0
$Global:TotalWarnings = 0

function Registrar-Falla {
    param(
        [string]$Modulo,
        [string]$Archivo,
        [string]$Detalle,
        [string]$Nivel = "ERROR"
    )
    if ($Nivel -eq "ERROR") {
        $Global:TotalErrores++
        Write-Host " [CRITICO] " -ForegroundColor Red -NoNewline
    } else {
        $Global:TotalWarnings++
        Write-Host " [ALERTA]  " -ForegroundColor Yellow -NoNewline
    }
    Write-Host "[$Modulo] " -ForegroundColor White -NoNewline
    Write-Host "$Archivo " -ForegroundColor Cyan -NoNewline
    Write-Host "-> $Detalle" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# 1. INSPECCION DE CODIFICACION, BOM Y MOJIBAKE
# -----------------------------------------------------------------------------
Write-Host "[1/6] Analizando Codificacion, BOM y Caracteres Corruptos (Mojibake)..." -ForegroundColor Yellow

$ArchivosTexto = Get-ChildItem -Path @("src", "tests", "docs") -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Extension.ToLower() -in @('.cs', '.csproj', '.ts', '.tsx', '.json', '.md', '.ps1') -and
    $_.FullName -notmatch '\\/[\\/]'
}

foreach ($f in $ArchivosTexto) {
    $rel = $f.FullName.Replace($RootPath, "").TrimStart('\', '/').Replace('\', '/')
    try {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            if ($Fix) {
                [System.IO.File]::WriteAllBytes($f.FullName, $bytes[3..($bytes.Length - 1)])
                Write-Host " [REPARADO] [BOM] $rel -> UTF-8 BOM eliminado" -ForegroundColor Green
            } else {
                Registrar-Falla "ENCODING" $rel "Contiene UTF-8 BOM (puede provocar errores de parseo)"
            }
        }
    } catch {}

    $contenido = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($contenido) {
        if ($Fix -and $contenido -match "(\u00C3[\u0080-\u00BF]|\u00E2\u0088\u009E|\u00F0\u0178|\u00E2\u20AC)") {
            try {
                $enc1252 = [System.Text.Encoding]::GetEncoding(1252)
                $encUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
                $bytesFixed = $enc1252.GetBytes($contenido)
                $fixedContenido = $encUtf8.GetString($bytesFixed)
                $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                [System.IO.File]::WriteAllText($f.FullName, $fixedContenido, $utf8NoBom)
                $contenido = $fixedContenido
                Write-Host " [REPARADO] [MOJIBAKE] $rel -> Caracteres restaurados a UTF-8" -ForegroundColor Green
            } catch {}
        }

        # Patrones de mojibake expresados en secuencias Unicode ASCII puras
        if ($contenido -match "(\u00C3[\u0080-\u00BF]|\u00E2\u0088\u009E|\u00F0\u0178)") {
            Registrar-Falla "MOJIBAKE" $rel "Caracteres con codificacion corrupta detectados (tildes/simbolos deformados)" "ALERTA"
        }
    }
}

# -----------------------------------------------------------------------------
# 2. DIAGNOSTICO DE ARQUITECTURA ONION Y PERSISTENCIA (.NET 8)
# -----------------------------------------------------------------------------
Write-Host "[2/6] Analizando Arquitectura Onion, Contratos y Persistencia..." -ForegroundColor Yellow

$proyectosRequeridos = @(
    "src/ADSOLUSOL.Domain/ADSOLUSOL.Domain.csproj",
    "src/ADSOLUSOL.Application/ADSOLUSOL.Application.csproj",
    "src/ADSOLUSOL.Infrastructure/ADSOLUSOL.Infrastructure.csproj",
    "src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj",
    "src/ADSOLUSOL.Presentation.Desktop/ADSOLUSOL.Presentation.Desktop.csproj"
)
foreach ($pr in $proyectosRequeridos) {
    if (-not (Test-Path (Join-Path $RootPath $pr))) {
        Registrar-Falla "ONION_CORE" $pr "Proyecto arquitectonico ausente"
    }
}

$repositorios = Get-ChildItem -Path (Join-Path $RootPath "src/ADSOLUSOL.Infrastructure/Repositories") -Filter "*.cs" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @("CreativeRepository.cs", "PlacementRepository.cs") }
foreach ($repo in $repositorios) {
    $content = Get-Content $repo.FullName -Raw -Encoding UTF8
    if ($content -match "public\s+async\s+Task\s+CreateAsync") {
        Registrar-Falla "REPO_CONTRACT" $repo.Name "Contrato asincrono invalido: debe devolver Task<long> en vez de Task"
    }
}

# -----------------------------------------------------------------------------
# 3. DIAGNOSTICO CRIPTOGRAFICO Y BLINDAJE ED25519 (SOLUSOL_AUTH_V1)
# -----------------------------------------------------------------------------
Write-Host "[3/6] Analizando Blindaje Criptografico, Middleware y Firmas Ed25519..." -ForegroundColor Yellow

$middleware = Join-Path $RootPath "src/ADSOLUSOL.Presentation.Api/Middleware/SignatureVerificationMiddleware.cs"
if (Test-Path $middleware) {
    $mwContent = Get-Content $middleware -Raw -Encoding UTF8
    $requiredHeaders = @("X-Solusol-Node-Id", "X-Solusol-Timestamp", "X-Solusol-Nonce", "X-Solusol-Signature")
    foreach ($h in $requiredHeaders) {
        if ($mwContent -notmatch $h) {
            Registrar-Falla "CRYPTO_AUTH" "SignatureVerificationMiddleware.cs" "Falta validacion del encabezado canonico $h"
        }
    }
} else {
    Registrar-Falla "ESTRUCTURA" "SignatureVerificationMiddleware.cs" "Middleware de seguridad ausente"
}

# -----------------------------------------------------------------------------
# 4. DIAGNOSTICO FRONTEND WEB (React 18 + Vite) & MAUI DESKTOP
# -----------------------------------------------------------------------------
Write-Host "[4/6] Analizando Frontend Web React y Contenedor MAUI Blazor..." -ForegroundColor Yellow

$WebPkg = Join-Path $RootPath "src/ADSOLUSOL.Presentation.Web/package.json"
if (Test-Path $WebPkg) {
    $pkgContent = Get-Content $WebPkg -Raw -Encoding UTF8
    if ($pkgContent -notmatch '"react":\s*"18\.') {
        Registrar-Falla "WEB_STACK" "package.json" "Version de React divergente (se requiere React 18)"
    }
} else {
    Registrar-Falla "ESTRUCTURA" "src/ADSOLUSOL.Presentation.Web/package.json" "Panel Web no encontrado"
}

$MauiProgram = Join-Path $RootPath "src/ADSOLUSOL.Presentation.Desktop/MauiProgram.cs"
if (Test-Path $MauiProgram) {
    $mauiContent = Get-Content $MauiProgram -Raw -Encoding UTF8
    if ($mauiContent -notmatch "AddMauiBlazorWebView") {
        Registrar-Falla "MAUI_CONTAINER" "MauiProgram.cs" "Falta inicializacion de Blazor WebView"
    }
} else {
    Registrar-Falla "ESTRUCTURA" "MauiProgram.cs" "Punto de entrada de escritorio MAUI no localizado"
}

# -----------------------------------------------------------------------------
# 5. CALIDAD DE CODIGO Y ZERO-SYNTHETIC (C#)
# -----------------------------------------------------------------------------
Write-Host "[5/6] Analizando Olores de Codigo, Zero-Synthetic y Bloques Catch..." -ForegroundColor Yellow

$csFiles = Get-ChildItem -Path @("src", "tests") -Filter "*.cs" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\/[\\/]' }

foreach ($cs in $csFiles) {
    $relCs = $cs.FullName.Replace($RootPath, "").TrimStart('\', '/').Replace('\', '/')
    $content = Get-Content $cs.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($content -match "NotImplementedException") {
        Registrar-Falla "CODE_SMELL" $relCs "NotImplementedException presente en el codigo"
    }
}

$Necroticos = Get-ChildItem -Path $RootPath -Recurse -File -Include "*.tmp","*.bak","*.orig","*~","*.swp" -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch '[\\/](\.git|node_modules|build|dist|out)[\\/]'
}
foreach ($n in $Necroticos) {
    $relN = $n.FullName.Replace($RootPath, "").TrimStart('\', '/')
    if ($Fix) {
        Remove-Item $n.FullName -Force -ErrorAction SilentlyContinue
        Write-Host " [REPARADO] [NECROSIS] $relN -> Archivo temporal eliminado" -ForegroundColor Green
    } else {
        Registrar-Falla "NECROSIS" $relN "Archivo temporal o respaldo residual presente en repositorio" "ALERTA"
    }
}

# -----------------------------------------------------------------------------
# 6. RESUMEN DIAGNÓSTICO FINAL
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[6/6] Consolidando Dictamen..." -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                    DICTAMEN DEL DIAGNOSTICO                      " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

if ($Global:TotalErrores -eq 0 -and $Global:TotalWarnings -eq 0) {
    Write-Host "`n[10/10 PERFECTO] El proyecto esta libre de fallos criticos y advertencias." -ForegroundColor Green
    Write-Host "Listo para certificacion y ejecucion de Junta Medica.`n" -ForegroundColor DarkGray
    exit 0
} elseif ($Global:TotalErrores -eq 0) {
    Write-Host "`n[APROBADO CON ADVERTENCIAS] 0 errores criticos, $($Global:TotalWarnings) advertencias menores." -ForegroundColor Yellow
    Write-Host "Se recomienda atender las advertencias para alcanzar la calificacion 10/10.`n" -ForegroundColor DarkGray
    exit 0
} else {
    Write-Host "`n[REPROBADO] Se encontraron $($Global:TotalErrores) errores criticos y $($Global:TotalWarnings) advertencias." -ForegroundColor Red
    Write-Host "Corrige los puntos listados arriba antes de correr la auditoria final.`n" -ForegroundColor DarkGray
    exit 1
}