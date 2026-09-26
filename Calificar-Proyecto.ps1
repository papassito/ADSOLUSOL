# ======================================================
# ADSOLUSOL - AUDITORIA Y CALIFICACION DE PROYECTO (.NET 8)
# ======================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TargetDir = ""
)

try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $TargetDir -or -not (Test-Path -LiteralPath $TargetDir)) {
    $TargetDir = (Get-Location).Path
}

Push-Location $TargetDir
try {
    $Score = 0
    $MaxScore = 100

    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "   AUDITORIA DE SALUD DE PROYECTO (.NET 8)     " -ForegroundColor Yellow
    Write-Host "=================================================`n" -ForegroundColor Cyan

    # --- Verificación de Entorno Base ---
    Write-Host "[ENTORNO] Verificando herramientas base..." -ForegroundColor Yellow

    $dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($dotnetCmd) {
        $dotnetVersion = (& dotnet --version).Trim()
        $majorVersion = [int]($dotnetVersion.Split('.')[0])
        Write-Host "  [+] .NET SDK instalado: $dotnetVersion" -ForegroundColor Green
        if ($majorVersion -ge 8) {
            $Score += 15
        } else {
            $Score += 10
        }
    } else {
        Write-Host "  [-] .NET SDK NO detectado en el sistema" -ForegroundColor Red
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "  [+] Git instalado" -ForegroundColor Green
        $Score += 5
    } else {
        Write-Host "  [-] Git NO detectado" -ForegroundColor DarkGray
    }

    # 2. Estructura de la Solución (30 Puntos)
    Write-Host ""
    Write-Host "[2/3] Verificando Estructura de la Solucion..." -ForegroundColor Yellow

    $sln = Get-ChildItem -Path . -Filter "*.sln" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sln) {
        Write-Host "  [+] Archivo de solucion encontrado: $($sln.Name)" -ForegroundColor Green
        $Score += 10
    } else {
        Write-Host "  [-] Archivo .sln no encontrado en: $TargetDir" -ForegroundColor Red
    }

    if (Test-Path "src") {
        Write-Host "  [+] Directorio fuente src/ segregado" -ForegroundColor Green
        $Score += 10
    } else {
        Write-Host "  [-] Carpeta /src no encontrada" -ForegroundColor Red
    }

    if (Test-Path "tests") {
        Write-Host "  [+] Directorio de pruebas tests/ segregado" -ForegroundColor Green
        $Score += 10
    } else {
        Write-Host "  [-] Carpeta /tests no encontrada" -ForegroundColor Yellow
    }

    # 3. Compilación y Pruebas Unitarias / Regresión (50 Puntos)
    Write-Host ""
    Write-Host "[3/3] Evaluando Compilacion y Suites de Regresion..." -ForegroundColor Yellow

    if ($sln) {
        Write-Host "  [*] Compilando solucion con 'dotnet build' (Release)..." -ForegroundColor Gray
        $buildParams = @(
            "build", $sln.FullName,
            "-c", "Release",
            "-p:IgnoreMissingWorkloads=true",
            "-p:WindowsPackageType=None",
            "-p:AppxPackage=false",
            "-p:GenerateAppxPackageOnBuild=false",
            "-p:WindowsAppSDKSelfContained=false",
            "-v:quiet",
            "--nologo"
        )
        $buildOut = & dotnet @buildParams 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [+] La solucion compila en Release sin errores" -ForegroundColor Green
            $Score += 25
        } else {
            Write-Host "  [-] Error en compilación de la solución" -ForegroundColor Red
        }

        Write-Host "  [*] Ejecutando suites con 'dotnet test'..." -ForegroundColor Gray
        $testOut = & dotnet test $sln.FullName --no-build -c Release -v:quiet --nologo 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [+] 100% de suites de pruebas aprobadas" -ForegroundColor Green
            $Score += 25
        } else {
            Write-Host "  [-] Fallaron una o más pruebas" -ForegroundColor Red
        }
    } else {
        Write-Host "  [-] No se pudo compilar ni probar sin archivo .sln" -ForegroundColor Red
    }

    # 4. Resultado y Diagnostico
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "            RESULTADO FINAL               " -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan

    if ($Score -ge 90) { 
        $Grade = "A+ (Proyecto Solido y Listo para Red/Pruebas)"; $Color = "Green" 
    } elseif ($Score -ge 75) { 
        $Grade = "A (Buen estado, compila correctamente)"; $Color = "Green" 
    } elseif ($Score -ge 60) { 
        $Grade = "B (En desarrollo, faltan binarios o dependencias)"; $Color = "Yellow" 
    } elseif ($Score -ge 40) { 
        $Grade = "C (Estructura inicial, falta completar codigo)"; $Color = "Yellow" 
    } else { 
        $Grade = "F (Incompleto o entorno no preparado)"; $Color = "Red" 
    }

    Write-Host "Puntuacion de Salud: $Score / $MaxScore" -ForegroundColor $Color
    Write-Host "Calificacion del Proyecto: $Grade" -ForegroundColor $Color
    Write-Host ""
} finally {
    Pop-Location
}