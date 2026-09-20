# ============================================================================
# BUILD-ADSOLUSOL.ps1
# Compilación Release + Frontend + Publish
# ============================================================================

[CmdletBinding()]
param(
    [string]$Root = "Y:\Documentos\GitHub\ADSOLUSOL"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$BuildFailed = $false

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL - BUILD RELEASE" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# 1. RUTAS
# ---------------------------------------------------------------------------

$Solution = Join-Path $Root "ADSOLUSOL.sln"

$ApiProject = Join-Path `
    $Root `
    "src\ADSOLUSOL.Presentation.Api\ADSOLUSOL.Presentation.Api.csproj"

$ApiWwwRoot = Join-Path `
    $Root `
    "src\ADSOLUSOL.Presentation.Api\wwwroot"

$FinalBuild = Join-Path `
    $Root `
    "BUILD\ADSOLUSOL"

# ---------------------------------------------------------------------------
# 2. VALIDACIONES
# ---------------------------------------------------------------------------

if (-not (Test-Path $Root)) {
    Write-Host "[FAIL] No existe la raíz:" -ForegroundColor Red
    Write-Host $Root -ForegroundColor Red
    return
}

Set-Location $Root

if (-not (Test-Path $Solution)) {
    Write-Host "[FAIL] No existe ADSOLUSOL.sln" -ForegroundColor Red
    return
}

if (-not (Test-Path $ApiProject)) {
    Write-Host "[FAIL] No existe el proyecto API:" -ForegroundColor Red
    Write-Host $ApiProject -ForegroundColor Red
    return
}

$Dotnet = Get-Command dotnet -ErrorAction SilentlyContinue

if (-not $Dotnet) {
    Write-Host "[FAIL] dotnet no está disponible." -ForegroundColor Red
    return
}

Write-Host "[OK] Root: $Root" -ForegroundColor Green
Write-Host "[OK] .NET: $($Dotnet.Source)" -ForegroundColor Green

$DotnetVersion = & dotnet --version

Write-Host "[OK] SDK: $DotnetVersion" -ForegroundColor Green
Write-Host ""

# ---------------------------------------------------------------------------
# 3. RESTORE
# ---------------------------------------------------------------------------

Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [1/5] RESTORE" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

& dotnet restore $Solution

$RestoreCode = $LASTEXITCODE

if ($RestoreCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] RESTORE FALLÓ. Exit Code: $RestoreCode" -ForegroundColor Red
    return
}

Write-Host "[PASS] Restore" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 4. BUILD .NET
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [2/5] BUILD .NET RELEASE" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

& dotnet build `
    $Solution `
    -c Release `
    --no-restore `
    --nologo

$BuildCode = $LASTEXITCODE

if ($BuildCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] BUILD FALLÓ. Exit Code: $BuildCode" -ForegroundColor Red
    return
}

Write-Host ""
Write-Host "[PASS] Solución .NET compilada." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 5. FRONTEND
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [3/5] FRONTEND PRODUCTION BUILD" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

$PackageJson = Get-ChildItem `
    -Path $Root `
    -Filter "package.json" `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch "\\node_modules\\"
    } |
    Select-Object -First 1

if ($PackageJson) {

    $FrontendRoot = $PackageJson.Directory.FullName

    Write-Host "[INFO] Frontend detectado:" -ForegroundColor Gray
    Write-Host "       $FrontendRoot" -ForegroundColor Gray

    # FIX: Resolve the real physical path to avoid issues with subst'd drives.
    Write-Host "[INFO] Resolving real frontend path to prevent Vite path errors..." -ForegroundColor Gray
    $FrontendRealRoot = & node -e "const fs=require('fs'); process.stdout.write(fs.realpathSync.native(process.argv[1]));" "$FrontendRoot"
    Write-Host "[INFO] Frontend physical path: $FrontendRealRoot" -ForegroundColor Gray

    $Npm = Get-Command npm -ErrorAction SilentlyContinue

    if (-not $Npm) {
        Write-Host "[FAIL] npm no está disponible." -ForegroundColor Red
        return
    }

    Push-Location $FrontendRealRoot

    try {

        $PackageLock = Join-Path $FrontendRoot "package-lock.json"

        if (Test-Path $PackageLock) {
            Write-Host "[INFO] Ejecutando npm ci..." -ForegroundColor Gray

            & npm ci

            if ($LASTEXITCODE -ne 0) {
                Write-Host "[FAIL] npm ci falló." -ForegroundColor Red
                return
            }
        }
        else {
            Write-Host "[INFO] package-lock.json ausente. Ejecutando npm install..." -ForegroundColor Gray

            & npm install

            if ($LASTEXITCODE -ne 0) {
                Write-Host "[FAIL] npm install falló." -ForegroundColor Red
                return
            }
        }

        & npm run build

        $FrontendBuildCode = $LASTEXITCODE

        if ($FrontendBuildCode -ne 0) {
            Write-Host "[FAIL] Frontend build falló." -ForegroundColor Red
            return
        }

        Write-Host "[PASS] Frontend compilado." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }

    # -----------------------------------------------------------------------
    # LOCALIZAR DIST
    # -----------------------------------------------------------------------

    $DistCandidates = @(
        (Join-Path $FrontendRoot "dist"),
        (Join-Path $FrontendRoot "build")
    )

    $FrontendDist = $DistCandidates |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1

    if (-not $FrontendDist) {
        Write-Host "[FAIL] No se encontró dist/build del frontend." -ForegroundColor Red
        return
    }

    # -----------------------------------------------------------------------
    # COPIAR FRONTEND A WWWROOT
    # -----------------------------------------------------------------------

    Write-Host ""
    Write-Host "[INFO] Integrando frontend en wwwroot..." -ForegroundColor Gray

    if (Test-Path $ApiWwwRoot) {
        Remove-Item `
            (Join-Path $ApiWwwRoot "*") `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
    else {
        New-Item `
            -ItemType Directory `
            -Path $ApiWwwRoot `
            -Force |
            Out-Null
    }

    Copy-Item `
        (Join-Path $FrontendDist "*") `
        $ApiWwwRoot `
        -Recurse `
        -Force

    $IndexHtml = Join-Path $ApiWwwRoot "index.html"

    if (-not (Test-Path $IndexHtml)) {
        Write-Host "[FAIL] wwwroot\index.html no fue generado." -ForegroundColor Red
        return
    }

    Write-Host "[PASS] Frontend integrado en API/wwwroot." -ForegroundColor Green
}
else {
    Write-Host "[WARNING] No se encontró package.json. Se continúa con backend." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 6. REBUILD DESPUÉS DE INTEGRAR FRONTEND
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [4/5] BUILD FINAL" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

Set-Location $Root

& dotnet build `
    $Solution `
    -c Release `
    --no-restore `
    --nologo

$FinalBuildCode = $LASTEXITCODE

if ($FinalBuildCode -ne 0) {
    Write-Host "[FAIL] Build final falló." -ForegroundColor Red
    return
}

Write-Host "[PASS] Build final." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 7. PUBLISH
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Yellow
Write-Host " [5/5] PUBLISH" -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Yellow

if (Test-Path $FinalBuild) {
    Write-Host "[INFO] Limpiando artefacto anterior..." -ForegroundColor Gray

    Remove-Item `
        $FinalBuild `
        -Recurse `
        -Force
}

New-Item `
    -ItemType Directory `
    -Path $FinalBuild `
    -Force |
    Out-Null

& dotnet publish `
    $ApiProject `
    -c Release `
    --no-restore `
    --nologo `
    -o $FinalBuild

$PublishCode = $LASTEXITCODE

if ($PublishCode -ne 0) {
    Write-Host ""
    Write-Host "[FAIL] PUBLISH FALLÓ. Exit Code: $PublishCode" -ForegroundColor Red
    return
}

# ---------------------------------------------------------------------------
# 8. VERIFICACIÓN ARTEFACTO
# ---------------------------------------------------------------------------

$PublishedDll = Join-Path `
    $FinalBuild `
    "ADSOLUSOL.Presentation.Api.dll"

if (-not (Test-Path $PublishedDll)) {
    Write-Host ""
    Write-Host "[FAIL] Publish terminó pero falta ADSOLUSOL.Presentation.Api.dll" -ForegroundColor Red
    return
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host " ADSOLUSOL - BUILD COMPLETADO" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "RESTORE  : PASS" -ForegroundColor Green
Write-Host "BUILD    : PASS" -ForegroundColor Green

if ($PackageJson) {
    Write-Host "FRONTEND : PASS" -ForegroundColor Green
}
else {
    Write-Host "FRONTEND : NOT FOUND" -ForegroundColor Yellow
}

Write-Host "PUBLISH  : PASS" -ForegroundColor Green
Write-Host ""
Write-Host "ARTEFACTO FINAL:" -ForegroundColor Cyan
Write-Host $FinalBuild -ForegroundColor White
Write-Host ""
Write-Host "API:" -ForegroundColor Cyan
Write-Host $PublishedDll -ForegroundColor White
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green