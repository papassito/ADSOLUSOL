# ======================================================
# KLIK REMOTE - AUDITORIA Y CALIFICACION DE PROYECTO
# ======================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TargetDir = ""
)

if (-not $TargetDir -or -not (Test-Path $TargetDir)) {
    if (Test-Path ".\Cargo.toml") {
        $TargetDir = (Get-Location).Path
    } elseif (Test-Path ".\klik-remote\Cargo.toml") {
        $TargetDir = (Resolve-Path ".\klik-remote").Path
    } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "klik-remote\Cargo.toml"))) {
        $TargetDir = (Resolve-Path (Join-Path $PSScriptRoot "klik-remote")).Path
    } else {
        $TargetDir = (Get-Location).Path
    }
}

Push-Location $TargetDir
try {
    $Score = 0
    $MaxScore = 100

    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "   AUDITORIA DE SALUD DE PROYECTO (Generico)   " -ForegroundColor Yellow
    Write-Host "=================================================`n" -ForegroundColor Cyan

    # --- Verificación de Entorno Base ---
    Write-Host "[ENTORNO] Verificando herramientas base..." -ForegroundColor Yellow

    if (Get-Command rustc -ErrorAction SilentlyContinue) {
        $rustVersion = rustc --version
        Write-Host "  [+] Rust instalado: $rustVersion" -ForegroundColor Green
        $Score += 15
    } else {
        Write-Host "  [-] Rust NO detectado en el sistema" -ForegroundColor Red
    }

    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        Write-Host "  [+] Cargo instalado" -ForegroundColor Green
        $Score += 10
    } else {
        Write-Host "  [-] Cargo NO detectado" -ForegroundColor Red
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "  [+] Git instalado" -ForegroundColor Green
        $Score += 5
    } else {
        Write-Host "  [-] Git NO detectado" -ForegroundColor DarkGray
    }

    # 2. Estructura del Proyecto (30 Puntos)
    Write-Host ""
    Write-Host "[2/3] Verificando Estructura de Archivos..." -ForegroundColor Yellow

    if (Test-Path "Cargo.toml") {
        Write-Host "  [+] Cargo.toml presente" -ForegroundColor Green
        $Score += 15
    } else {
        Write-Host "  [-] Cargo.toml no encontrado en: $TargetDir" -ForegroundColor Red
    }

    if (Test-Path "src/main.rs") {
        Write-Host "  [+] Punto de entrada src/main.rs encontrado" -ForegroundColor Green
        $Score += 15
    } elseif (Test-Path "src") {
        Write-Host "  [+] Carpeta src/ presente pero falta main.rs" -ForegroundColor Yellow
        $Score += 5
    } else {
        Write-Host "  [-] Carpeta /src no encontrada" -ForegroundColor Red
    }

    # 3. Compilación y Código (40 Puntos)
    Write-Host ""
    Write-Host "[3/3] Evaluando Estado del Codigo y Compilacion..." -ForegroundColor Yellow

    if (Test-Path "Cargo.toml") {
        Write-Host "  [*] Ejecutando 'cargo check' (Verificando sintaxis y tipos)..." -ForegroundColor Gray
        
        $checkProcess = Start-Process cargo -ArgumentList "check" -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        
        if ($checkProcess -and $checkProcess.ExitCode -eq 0) {
            Write-Host "  [+] El proyecto compila perfectamente sin errores" -ForegroundColor Green
            $Score += 25
        } else {
            Write-Host "  [-] El codigo tiene errores de compilacion" -ForegroundColor Red
        }

        $binaries = Get-ChildItem -Path "target" -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        if ($binaries) {
            Write-Host "  [+] Executable .exe compilado encontrado en /target" -ForegroundColor Green
            $Score += 15
        } else {
            Write-Host "  [-] No se ha generado ejecutable aun (Ejecuta 'cargo build')" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [-] No se pudo probar la compilacion sin Cargo.toml" -ForegroundColor Red
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