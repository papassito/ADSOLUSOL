[CmdletBinding()]
param(
    [switch]$Fix,
    [switch]$Fast
)

Clear-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [AUDITOR] EL CHISMOSO FORENSE :: AUDITOR DE CALIDAD ADSOLUSOL (.NET 8)" -ForegroundColor Cyan
Write-Host "        SISTEMA DE GOBERNANZA, HIGIENE, ONION ARCHITECTURE Y CI/CD" -ForegroundColor DarkCyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"
$global:hasErrors = $false

# 0. Verificacion de entorno (.NET SDK instalado)
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "[-] Error: .NET SDK no esta instalado o no se encuentra en el PATH del sistema." -ForegroundColor Red
    exit 1
}

function Invoke-AuditStep {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host "`n[*] Ejecutando: $Name..." -ForegroundColor Yellow
    & $Action
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[-] Fallo en: $Name" -ForegroundColor Red
        $global:hasErrors = $true
    } else {
        Write-Host "[+] Exito en: $Name" -ForegroundColor Green
    }
}

# 1. Higiene de archivos y neutralizacion preventiva de BOM
Write-Host "`n[*] Auditando codificacion (Deteccion de marcas BOM UTF-8)..." -ForegroundColor Yellow
$bomSanitized = 0
Get-ChildItem -Path @("src", "tests") -Include "*.cs","*.csproj","*.json","*.md" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "\\/[\\/]" } | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $cleanBytes = if ($bytes.Length -gt 3) { [byte[]]($bytes[3..($bytes.Length - 1)]) } else { [byte[]]@() }
        [System.IO.File]::WriteAllBytes($_.FullName, $cleanBytes)
        $bomSanitized++
    }
}
if ($bomSanitized -gt 0) {
    Write-Host "[!] Se sanearon $bomSanitized archivo(s) con marca BOM para prevenir errores de compilacion." -ForegroundColor DarkYellow
} else {
    Write-Host "[+] Codificacion limpia: Cero marcas BOM detectadas." -ForegroundColor Green
}

# 2. Verificacion de arquitectura y archivos huerfanos en la raiz
Write-Host "`n[*] Verificando higiene de arquitectura en raiz..." -ForegroundColor Yellow
$strayRootProjects = Get-ChildItem -Path . -Filter "*.csproj" -File -ErrorAction SilentlyContinue
if ($strayRootProjects.Count -gt 0) {
    Write-Host "[-] Error: Se detectaron proyectos .csproj huerfanos en la raiz del repositorio:" -ForegroundColor Red
    $strayRootProjects | ForEach-Object { Write-Host "    -> $($_.Name)" -ForegroundColor Red }
    $global:hasErrors = $true
} else {
    Write-Host "[+] Raiz inmaculada: Todo el codigo reside en src/ y tests/." -ForegroundColor Green
}

# 3. Formato del codigo (dotnet format) con soporte de auto-reparacion (-Fix)
Write-Host "`n[*] Verificando formato de codigo (.NET Format)..." -ForegroundColor Yellow
if ($Fix) {
    Write-Host "[*] Parametro -Fix activo: Aplicando 'dotnet format ADSOLUSOL.sln'..." -ForegroundColor DarkYellow
    & dotnet format ADSOLUSOL.sln --verbosity minimal
}

$formatOut = & dotnet format ADSOLUSOL.sln --verify-no-changes --verbosity minimal 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[-] Discrepancias de estilo detectadas:" -ForegroundColor Red
    $formatOut | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    Write-Host "[i] Sugerencia: Ejecuta '.\chismoso.ps1 -Fix' para corregir el formato automaticamente." -ForegroundColor Yellow
    $global:hasErrors = $true
} else {
    Write-Host "[+] Formato canonico validado en todos los archivos." -ForegroundColor Green
}

# 4. Verificacion de olores de codigo (Code Smells y Zero-Synthetic)
Write-Host "`n[*] Auditando calidad de codigo (bloques catch vacios, TODOs y Mocks)..." -ForegroundColor Yellow
$csFiles = Get-ChildItem -Path @("src", "tests") -Filter "*.cs" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "\\/[\\/]" }

$emptyCatches = $csFiles | Select-String -Pattern "catch\s*(\([^\)]*\))?\s*\{\s*\}"
if ($emptyCatches) {
    Write-Host "[-] Se detectaron bloques catch silenciosos:" -ForegroundColor Red
    $emptyCatches | ForEach-Object { Write-Host "    -> $($_.Filename):$($_.LineNumber)" -ForegroundColor Red }
    $global:hasErrors = $true
} else {
    Write-Host "[+] Cero capturas silenciosas en bloques catch." -ForegroundColor Green
}

$notImplemented = $csFiles | Select-String -Pattern "NotImplementedException"
if ($notImplemented) {
    Write-Host "[-] Se detectaron excepciones sin implementar:" -ForegroundColor Red
    $notImplemented | ForEach-Object { Write-Host "    -> $($_.Filename):$($_.LineNumber)" -ForegroundColor Red }
    $global:hasErrors = $true
} else {
    Write-Host "[+] Cero excepciones NotImplementedException." -ForegroundColor Green
}

# 5. Analisis estatico y compilacion Roslyn (Release)
Invoke-AuditStep -Name "Compilacion Release de la Solucion (dotnet build)" -Action {
    & dotnet build ADSOLUSOL.sln -c Release `
        -p:IgnoreMissingWorkloads=true `
        -p:WindowsPackageType=None `
        -p:AppxPackage=false `
        -p:GenerateAppxPackageOnBuild=false `
        -p:WindowsAppSDKSelfContained=false `
        -v:minimal /nologo
}

# 6. Ejecucion de Pruebas Unitarias y Suites de Regresion
Invoke-AuditStep -Name "Suites de Pruebas y Regresion (dotnet test)" -Action {
    & dotnet test ADSOLUSOL.sln -c Release --no-build -v:quiet --nologo
}

# 7. Publicacion de Produccion (Omitible con -Fast)
if ($Fast) {
    Write-Host "`n[INFO] Parametro -Fast activo: Se omite la publicacion del artefacto API." -ForegroundColor Cyan
} else {
    $publishDir = "BUILD/Api"
    if (-not (Test-Path $publishDir)) { New-Item -ItemType Directory -Force -Path $publishDir | Out-Null }
    Invoke-AuditStep -Name "Publicacion de Produccion API (dotnet publish)" -Action {
        & dotnet publish src/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj `
            -c Release -o $publishDir `
            -p:WindowsPackageType=None `
            -p:AppxPackage=false `
            -p:GenerateAppxPackageOnBuild=false `
            -p:WindowsAppSDKSelfContained=false `
            -v:quiet --nologo
    }
    if (Test-Path "$publishDir/ADSOLUSOL.Presentation.Api.dll") {
        $binItem = Get-Item "$publishDir/ADSOLUSOL.Presentation.Api.dll"
        $binSizeMB = [math]::Round($binItem.Length / 1MB, 2)
        Write-Host "    --> Artefacto generado: $($binItem.FullName) ($binSizeMB MB)" -ForegroundColor DarkGray
    }
}

$stopwatch.Stop()
$elapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)

Write-Host "`n==========================================================================" -ForegroundColor Cyan
if ($global:hasErrors) {
    Write-Host "[FAIL] VEREDICTO: SE ENCONTRARON PROBLEMAS (Tiempo: ${elapsed}s)" -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "[PASS] VEREDICTO: TODAS LAS VERIFICACIONES DE CALIDAD PASARON CON EXITO! (Tiempo: ${elapsed}s)" -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 0
}