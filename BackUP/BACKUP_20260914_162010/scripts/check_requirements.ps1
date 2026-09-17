$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = if ($scriptDir) { Split-Path -Parent $scriptDir } else { $pwd.Path }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   ADSOLUSOL: DIAGNÓSTICO DE REQUISITOS Y LIBRERÍAS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Localizar y analizar el SDK de .NET
Write-Host "`n[1/3] Verificando SDK y Entorno de .NET..." -ForegroundColor Yellow

$dotnetPath = "C:\Users\Radio 2027\Documents\Codex\tools\dotnet\dotnet.exe"
if (-not (Test-Path $dotnetPath)) {
    $dotnetPath = (Get-Command dotnet -ErrorAction SilentlyContinue).Source
    if (-not $dotnetPath) {
        if ($env:ADSOLUSOL_DOTNET -and (Test-Path -LiteralPath $env:ADSOLUSOL_DOTNET)) {
            $dotnetPath = $env:ADSOLUSOL_DOTNET
        }
    }
}

if (-not $dotnetPath) {
    Write-Error "No se localizó un SDK de .NET compatible. Por favor, instale .NET 8.0."
} else {
    Write-Host "✔ Ejecutable .NET encontrado en: $dotnetPath" -ForegroundColor Green
    
    $sdkVersion = $null
    $sdkError = $null
    try {
        $sdkVersion = (& $dotnetPath --version 2>&1).ToString().Trim()
    } catch {
        $sdkError = $_.Exception.Message
    }

    if ($sdkVersion -and $sdkVersion -notmatch "could not be loaded" -and $sdkVersion -notmatch "No .NET SDKs") {
        Write-Host "✔ Versión de SDK activa: $sdkVersion" -ForegroundColor Green
    } else {
        Write-Warning "¡ATENCIÓN! El ejecutable detectado en esa ruta es un Runtime-only o está dañado (no se detectó SDK)."
        if ($sdkError) { Write-Host "Detalle: $sdkError" -ForegroundColor Gray }
        Write-Host "Se recomienda configurar la variable de entorno ADSOLUSOL_DOTNET apuntando a su SDK portable." -ForegroundColor Cyan
    }

    Write-Host "`nRuntimes detectados en la ruta de .NET:" -ForegroundColor Gray
    $runtimes = @()
    try {
        $runtimes = & $dotnetPath --list-runtimes 2>$null
    } catch {}
    if ($runtimes) {
        $runtimes | Out-String | Write-Host
    } else {
        Write-Host "Ninguno" -ForegroundColor Gray
    }

    # Comprobar específicamente ASP.NET Core v8.0.x
    $hasAspNetCore = $runtimes -match 'Microsoft.AspNetCore.App 8\.'
    if ($hasAspNetCore) {
        Write-Host "✔ Servidor ASP.NET Core Runtime (8.x) disponible." -ForegroundColor Green
    } else {
        Write-Warning "¡ATENCIÓN! No se detectó 'Microsoft.AspNetCore.App 8.x' en esta instalación de .NET."
        Write-Host "Si la API falla al arrancar, configure la variable de entorno DOTNET_ROOT apuntando a su SDK portable." -ForegroundColor Cyan
    }
}

# 2. Analizar dependencias NuGet en el código fuente
Write-Host "`n[2/3] Escaneando proyectos (.csproj) y librerías requeridas..." -ForegroundColor Yellow
$projects = Get-ChildItem -Path (Join-Path $root 'src') -Filter "*.csproj" -Recurse
if ($projects.Count -eq 0) {
    Write-Warning "No se encontraron proyectos .csproj en 'src/'."
} else {
    foreach ($proj in $projects) {
        $relPath = $proj.FullName.Substring($root.Length + 1)
        Write-Host "`n➡ Proyecto: $relPath" -ForegroundColor Cyan
        [xml]$xml = Get-Content -LiteralPath $proj.FullName -Raw
        $tfm = $xml.SelectSingleNode("//TargetFramework")
        if ($tfm) { Write-Host "   Framework Objetivo: $($tfm.InnerText)" -ForegroundColor Gray }
        
        $packages = $xml.SelectNodes("//PackageReference")
        if ($packages.Count -gt 0) {
            Write-Host "   Librerías externas:"
            foreach ($pkg in $packages) {
                Write-Host "     * $($pkg.Include) (v$($pkg.Version))" -ForegroundColor Gray
            }
        }
    }
}

# 3. Validar Persistencia Local
Write-Host "`n[3/3] Comprobando persistencia de base de datos local (SQLite)..." -ForegroundColor Yellow
$sqliteDb = Join-Path $root 'src\ADSOLUSOL.Presentation.Api\App_Data\campaigns.db'
if (Test-Path -LiteralPath $sqliteDb) {
    Write-Host "✔ Base de datos de campañas detectada en: $sqliteDb" -ForegroundColor Green
} else {
    Write-Host "ℹ No existe 'App_Data/campaigns.db' todavía. Se creará automáticamente al iniciar el servidor." -ForegroundColor Gray
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   Diagnóstico completado con éxito." -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan