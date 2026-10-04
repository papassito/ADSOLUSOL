# ======================================================
# AUDITORIA Y CALIFICACION UNIVERSAL DE PROYECTO (.NET 8)
# ======================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TargetDir = ""
)

if (-not $TargetDir -or -not (Test-Path $TargetDir)) {
    if ($PSScriptRoot -and (Test-Path -LiteralPath $PSScriptRoot)) {
        $TargetDir = (Resolve-Path $PSScriptRoot).Path
    } else {
        $TargetDir = (Get-Location).Path
    }
}

Push-Location $TargetDir
try {
    $Score = 0
    $MaxScore = 100

    # Detección de Stack tecnológico
    $slnFiles    = @(Get-ChildItem -Path $TargetDir -Filter "*.sln" -File -Recurse -Depth 2 -ErrorAction SilentlyContinue)
    $csprojFiles = @(Get-ChildItem -Path $TargetDir -Filter "*.csproj" -File -Recurse -Depth 3 -ErrorAction SilentlyContinue)
    $hasCargo    = Test-Path (Join-Path $TargetDir "Cargo.toml")
    $hasPackage  = Test-Path (Join-Path $TargetDir "package.json")
    $hasPython   = (Test-Path (Join-Path $TargetDir "requirements.txt")) -or (Test-Path (Join-Path $TargetDir "main.py")) -or (Test-Path (Join-Path $TargetDir "pyproject.toml"))
    $hasGo       = (Test-Path (Join-Path $TargetDir "go.mod")) -or (Get-ChildItem -Path $TargetDir -Filter "*.go" -File -Recurse -Depth 2 -ErrorAction SilentlyContinue).Count -gt 0

    $stack = "Generico"
    if ($slnFiles.Count -gt 0 -or $csprojFiles.Count -gt 0) {
        $stack = "DotNet"
    } elseif ($hasGo) {
        $stack = "Go"
    } elseif ($hasPython) {
        $stack = "Python"
    } elseif ($hasCargo) {
        $stack = "Rust"
    } elseif ($hasPackage) {
        $stack = "Node"
    }

    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "   AUDITORIA DE SALUD DE PROYECTO               " -ForegroundColor Yellow
    Write-Host "   Stack Detectado: $stack                       " -ForegroundColor DarkGray
    Write-Host "=================================================`n" -ForegroundColor Cyan

    # --- Verificación de Entorno Base ---
    Write-Host "[ENTORNO] Verificando herramientas base..." -ForegroundColor Yellow

    if ($stack -eq "Go") {
        if (Get-Command go -ErrorAction SilentlyContinue) {
            $goVersion = go version
            Write-Host "  [+] Go instalado: $goVersion" -ForegroundColor Green
            $Score += 25
        } else {
            Write-Host "  [-] Go NO detectado en el sistema" -ForegroundColor Red
        }
    } else {
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

    if ($stack -eq "Go") {
        if (Test-Path "go.mod") {
            Write-Host "  [+] go.mod presente" -ForegroundColor Green
            $Score += 15
        } else {
            Write-Host "  [-] go.mod no encontrado en: $TargetDir" -ForegroundColor Red
        }
        if ((Test-Path "internal") -or (Test-Path "cmd")) {
            Write-Host "  [+] Estructura estandar (internal/ o cmd/) detectada" -ForegroundColor Green
            $Score += 15
        } else {
            Write-Host "  [-] No se detectaron carpetas canonicas internal/ o cmd/" -ForegroundColor Red
        }
    } else {

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
    }

    # 3. Compilación y Código (40 Puntos)
    Write-Host ""
    Write-Host "[3/3] Evaluando Estado del Codigo y Compilacion..." -ForegroundColor Yellow

    if ($stack -eq "Go") {
        Write-Host "  [*] Ejecutando 'go vet ./...' (Analisis estatico)..." -ForegroundColor Gray
        $vetProcess = Start-Process go -ArgumentList "vet ./..." -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        if ($vetProcess -and $vetProcess.ExitCode -eq 0) {
            Write-Host "  [+] Analisis go vet superado exitosamente" -ForegroundColor Green
            $Score += 20
        } else {
            Write-Host "  [-] go vet detecto anomalias o fallos sintacticos" -ForegroundColor Red
        }

        Write-Host "  [*] Verificando compilabilidad con 'go build ./...'..." -ForegroundColor Gray
        $buildProcess = Start-Process go -ArgumentList "build ./..." -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
        if ($buildProcess -and $buildProcess.ExitCode -eq 0) {
            Write-Host "  [+] El proyecto compila sin errores" -ForegroundColor Green
            $Score += 20
        } else {
            Write-Host "  [-] Fallo al compilar paquetes Go" -ForegroundColor Red
        }
    } else {

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