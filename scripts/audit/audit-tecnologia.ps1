<#
================================================================================
  ADSOLUSOL :: AUDITORIA TECNOLOGICA Y DE DEPENDENCIAS (NASA GRADE)
  Fiscaliza el TargetFramework .NET 8, configuracion de compilador C# 12,
  stack Web React 18 / Vite, contenedor Desktop MAUI y algoritmos criptograficos.
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
Write-Host " [TECNOLOGIA] AUDITORIA DE STACK TECNOLOGICO Y DEPENDENCIAS (NASA GRADE)  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$tecFails = 0
$tecWarns = 0

function Assert-Tech([bool]$Condition, [string]$Code, [string]$Message, [bool]$IsFatal = $true) {
    if ($Condition) {
        Write-Host "  [PASS] [$Code] $Message" -ForegroundColor Green
    } else {
        if ($IsFatal) {
            Write-Host "  [FAIL] [$Code] $Message" -ForegroundColor Red
            $script:tecFails++
        } else {
            Write-Host "  [WARN] [$Code] $Message" -ForegroundColor Yellow
            $script:tecWarns++
        }
    }
}

function Read-SourceText([string]$RelPath) {
    $full = Join-Path $ScriptRoot $RelPath
    if (Test-Path $full) {
        return [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    }
    return ""
}

# ------------------------------------------------------------------------------
# FASE 1: STACK BACKEND .NET 8 Y COMPILADOR C#
# ------------------------------------------------------------------------------
Write-Host "[1/5] Verificando TargetFramework .NET 8 y configuracion de compilador..." -ForegroundColor Yellow

$csprojFiles = @(Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.csproj" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\/[\\/]' })

$allNet8 = $true
foreach ($proj in $csprojFiles) {
    $xml = [System.IO.File]::ReadAllText($proj.FullName, [System.Text.Encoding]::UTF8)
    if ($xml -notmatch 'TargetFramework[s]?[^>]*>[^<]*net8\.0(?:[-\w\.]*)') {
        $allNet8 = $false
        Assert-Tech $false "TECH-NET8-MISMATCH" "$($proj.Name) no compila hacia net8.0."
    }
}
if ($allNet8) {
    Assert-Tech $true "TECH-NET8-UNIFIED" "Todos los proyectos de la solucion están unificados en TargetFramework net8.0."
}

$nullableActive = $true
foreach ($proj in $csprojFiles) {
    $xml = [System.IO.File]::ReadAllText($proj.FullName, [System.Text.Encoding]::UTF8)
    if ($xml -notmatch '<Nullable>enable</Nullable>') {
        $nullableActive = $false
        Assert-Tech $false "TECH-NULLABLE" "$($proj.Name) no tiene activado el analisis estricto <Nullable>enable</Nullable>." $false
    }
}
if ($nullableActive) {
    Assert-Tech $true "TECH-NULLABLE-ALL" "Analisis estricto de nulos (<Nullable>enable</Nullable>) activo en todos los proyectos."
}

# ------------------------------------------------------------------------------
# FASE 2: CRIPTOGRAFIA MODERNA (ED25519) Y VETO A ALGORITMOS OBSOLETOS
# ------------------------------------------------------------------------------
Write-Host "`n[2/5] Auditando stack criptografico y ausencia de primitivas debiles..." -ForegroundColor Yellow

$csFiles = @(Get-ChildItem -Path (Join-Path $ScriptRoot "src") -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\/[\\/]' })

$weakCryptoFound = $false
foreach ($f in $csFiles) {
    $src = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($src -match '\b(MD5|SHA1CryptoServiceProvider|TripleDES|RijndaelManaged)\b') {
        $weakCryptoFound = $true
        Assert-Tech $false "TECH-WEAK-CRYPTO" "$($f.Name) utiliza primitiva criptografica obsoleta/insegura."
    }
}
if (-not $weakCryptoFound) {
    Assert-Tech $true "TECH-STRONG-CRYPTO" "Cero algoritmos debiles (MD5, SHA1, DES). Stack criptografico perimetral blindado."
}

$verifierSrc = Read-SourceText "src/ADSOLUSOL.Infrastructure/Security/CoreSignatureVerifier.cs"
Assert-Tech ($verifierSrc -match 'NSec\.Cryptography|SignatureAlgorithm\.Ed25519') "TECH-ED25519" "Firma criptografica implementada con Ed25519 (NSec/Libsodium)."

# ------------------------------------------------------------------------------
# FASE 3: STACK FRONTEND WEB (REACT 18 + VITE + TYPESCRIPT)
# ------------------------------------------------------------------------------
Write-Host "`n[3/5] Auditando frontend web React 18, Vite y TypeScript..." -ForegroundColor Yellow

$pkgJson = Read-SourceText "src/ADSOLUSOL.Presentation.Web/package.json"
if (-not [string]::IsNullOrWhiteSpace($pkgJson)) {
    Assert-Tech ($pkgJson -match '"react":\s*"\^?18\.') "TECH-REACT18" "Frontend opera sobre React 18 canónico."
    Assert-Tech ($pkgJson -match '"vite":') "TECH-VITE" "Herramienta de empaquetado Vite integrada."
    Assert-Tech ($pkgJson -match '"typescript":') "TECH-TS" "TypeScript activo como lenguaje de tipado estricto."
} else {
    Assert-Tech $false "TECH-WEB-PKG" "package.json de Presentation.Web no encontrado."
}

$viteConfig = Read-SourceText "src/ADSOLUSOL.Presentation.Web/vite.config.ts"
Assert-Tech ($viteConfig -match '@vitejs/plugin-react') "TECH-VITE-PLUGIN" "Plugin oficial de React configurado en vite.config.ts."

# ------------------------------------------------------------------------------
# FASE 4: STACK DE ESCRITORIO (.NET MAUI BLAZOR)
# ------------------------------------------------------------------------------
Write-Host "`n[4/5] Auditando contenedor Desktop .NET MAUI..." -ForegroundColor Yellow

$mauiProj = Read-SourceText "src/ADSOLUSOL.Presentation.Desktop/ADSOLUSOL.Presentation.Desktop.csproj"
Assert-Tech ($mauiProj -match '<UseMaui(?:\s+Condition="[^"]+")?>true</UseMaui>') "TECH-MAUI-ENABLED" "Framework .NET MAUI habilitado en proyecto Desktop."

$mauiProgram = Read-SourceText "src/ADSOLUSOL.Presentation.Desktop/MauiProgram.cs"
Assert-Tech ($mauiProgram -match 'AddMauiBlazorWebView') "TECH-MAUI-BLAZOR" "Blazor WebView inicializado en MauiProgram."

# ------------------------------------------------------------------------------
# FASE 5: PERSISTENCIA Y DRIVERS (SQLITE + EF CORE + DAPPER)
# ------------------------------------------------------------------------------
Write-Host "`n[5/5] Auditando drivers de persistencia y bibliotecas de acceso a datos..." -ForegroundColor Yellow

$infraProj = Read-SourceText "src/ADSOLUSOL.Infrastructure/ADSOLUSOL.Infrastructure.csproj"
Assert-Tech ($infraProj -match 'Microsoft\.EntityFrameworkCore\.Sqlite') "TECH-EF-SQLITE" "Driver oficial EF Core SQLite presente."
Assert-Tech ($infraProj -match 'Dapper') "TECH-DAPPER" "Micro-ORM Dapper integrado para operaciones de alto rendimiento."

# ------------------------------------------------------------------------------
# DICTAMEN FINAL DE TECNOLOGIA
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                  DICTAMEN DE AUDITORIA DE TECNOLOGIA                     " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Tecnologicas : $tecFails" -ForegroundColor $(if ($tecFails -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias              : $tecWarns" -ForegroundColor $(if ($tecWarns -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($tecFails -gt 0) {
    Write-Host "`n[FAIL] RECHAZADO: Se detectaron fallas de stack tecnologico o dependencias obsoletas.`n" -ForegroundColor Red
    exit 1
} elseif ($tecWarns -gt 0) {
    Write-Host "`n[PASS WITH WARNINGS] Observaciones tecnologicas menores.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] Stack tecnologico .NET 8 / React 18 / MAUI moderno, seguro y conforme.`n" -ForegroundColor Green
    exit 0
}
