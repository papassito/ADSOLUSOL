<#
================================================================================
  ADSOLUSOL :: AUTOPSIA DE INTEGRIDAD ESTRUCTURAL v1.0
  "Analisis Forense de Sellos Documentales, Contencion Arquitectonica Onion
   y Toxicología de Dependencias de la Cadena de Suministro de Software."
================================================================================
#>
param(
    [string]$Root = ".",
    [switch]$Reseal
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Resolución canónica de la ruta raíz
$ScriptRoot = (Resolve-Path $Root).Path
Set-Location $ScriptRoot

# Rutina de Re-sellado Notarial si se invoca con -Reseal
if ($Reseal) {
    Write-Host "[NOTARÍA] Re-sellando hashes de documentación (SHA-256)..." -ForegroundColor Yellow
    $manifestFiles = @("docs/MANIFEST.md", "MANIFEST.md")
    $mdFiles = Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { 
            $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" -and
            $_.Name -ne "MANIFEST.md"
        } |
        Sort-Object -Property FullName

    $lines = @("# AD SOLUSOL — Documentation Manifest", "", "**Estado:** SEALED / FROZEN DOCUMENTATION BASELINE", "**Fecha de sellado:** $(Get-Date -Format 'yyyy-MM-dd')", "**Total de archivos Markdown del baseline:** $($mdFiles.Count)", "", "## SHA-256 de documentos sellados", "", "| Archivo | SHA-256 |", "|---|---|")
    foreach ($f in $mdFiles) {
        $rel = $f.FullName.Substring($ScriptRoot.Length).TrimStart("\", "/").Replace("\", "/")
        $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower()
        $lines += "| \`$rel\` | \`$hash\` |"
    }
    $content = ($lines -join "`r`n") + "`r`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($mp in $manifestFiles) {
        $target = Join-Path $ScriptRoot $mp
        $dir = Split-Path $target
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        [System.IO.File]::WriteAllText($target, $content, $utf8NoBom)
        Write-Host "  -> Manifiesto actualizado: $mp" -ForegroundColor Green
    }
}

Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host "   ADSOLUSOL :: AUTOPSIA DE INTEGRIDAD ESTRUCTURAL       " -ForegroundColor Magenta
Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host "Directorio del Examen: $ScriptRoot" -ForegroundColor DarkGray
Write-Host ""

# 2. Cuadro de Especialistas Forenses
$ForensicBoard = @(
    @{
        Area         = "Notaria Criptografica y Archivistica Forense"
        Especialista = "Verificacion de Sellos Documentales (SHA-256 vs MANIFEST.md)"
        Command      = '
            $manifestPath = "docs/MANIFEST.md"
            if (-not (Test-Path $manifestPath)) {
                $manifestPath = "MANIFEST.md"
            }
            if (-not (Test-Path $manifestPath)) {
                Write-Host "[CRITICO] No se encontró el MANIFEST.md para la verificación de sellos." -ForegroundColor Red
                exit 1
            }

            $manifestContent = Get-Content $manifestPath -Raw
            $regex = ''\|\s*[\x60]?([^\x60|\r\n]+?)[\x60]?\s*\|\s*[\x60]?([a-f0-9]{64})[\x60]?\s*\|''
            $matches = [regex]::Matches($manifestContent, $regex)

            if ($matches.Count -eq 0) {
                Write-Host "[CRITICO] No se pudieron extraer hashes del MANIFEST.md. ¿Formato de tabla incorrecto?" -ForegroundColor Red
                exit 1
            }

            $errors = 0
            foreach ($match in $matches) {
                $filePath = $match.Groups[1].Value.Trim()
                $expectedHash = $match.Groups[2].Value.Trim()

                if (Test-Path $filePath) {
                    $actualHash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash.ToLower()
                    if ($actualHash -ne $expectedHash) {
                        Write-Host "[SELLO ROTO] El archivo $filePath ha sido modificado." -ForegroundColor Red
                        Write-Host "  -> Hash esperado: $expectedHash" -ForegroundColor DarkGray
                        Write-Host "  -> Hash actual:   $actualHash" -ForegroundColor DarkGray
                        $errors++
                    }
                } else {
                    Write-Host "[SELLO ROTO] El archivo documentado $filePath no existe." -ForegroundColor Red
                    $errors++
                }
            }

            if ($errors -gt 0) {
                Write-Host "[FALLO] Se detectaron $errors violaciones de integridad documental." -ForegroundColor Red
                exit 1
            } else {
                Write-Host "[INTEGRO] $($matches.Count)/$($matches.Count) documentos verificados. Sello intacto."
            }
        '
        Descripcion  = "Verifica que el contenido de cada archivo de documentación coincida con su firma SHA-256 registrada en el manifiesto."
    },
    @{
        Area         = "Ingenieria Estructural y Urbanismo de Software"
        Especialista = "Validación de Dependencias de Arquitectura Onion (NetArchTest)"
        Command      = '
            $archTestProject = Get-ChildItem -Path "tests" -Filter "*ArchitectureTests.csproj" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $archTestProject) {
                Write-Host "[OBSERVACION] No se encontró un proyecto de pruebas de arquitectura (*ArchitectureTests.csproj)." -ForegroundColor Yellow
                Write-Host "Se recomienda crear uno para una validación profunda de las capas Onion." -ForegroundColor Yellow
                exit 0
            }

            Write-Host "Ejecutando pruebas de arquitectura para: $($archTestProject.Name)" -ForegroundColor Cyan
            $testOut = & dotnet test $archTestProject.FullName -c Release -v:q --nologo 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[VIOLACION ARQUITECTONICA] Se detectaron reglas arquitectonicas no cumplidas." -ForegroundColor Red
                $testOut | Where-Object { $_ -match "Failed|Exception|forbidden|Con error|Entidades" } | ForEach-Object { Write-Host "  -> $_" -ForegroundColor Red }
                exit 1
            }
            Write-Host "[ESTRUCTURA SOLIDA] Reglas Onion validadas sin infracciones."
        '
        Descripcion  = "Ejecuta una suite de pruebas dedicada a verificar que las dependencias entre proyectos (Domain, Application, Infrastructure) son correctas."
    },
    @{
        Area         = "Toxicologia de Dependencias y Cadena de Suministro"
        Especialista = "Escaneo de Vulnerabilidades en Paquetes NuGet"
        Command      = '
            $slnFile = Get-ChildItem -Path . -Filter "*.sln" | Select-Object -First 1
            if (-not $slnFile) {
                Write-Host "[CRITICO] No se encontró el archivo de solución .sln para analizar." -ForegroundColor Red
                exit 1
            }
            
            Write-Host "Analizando dependencias de la solución: $($slnFile.Name)" -ForegroundColor Cyan
            $vulnOut = & dotnet list $slnFile.FullName package --vulnerable --include-transitive 2>&1
            
            if ($vulnOut -join "`n" -match "has the following vulnerable packages") {
                Write-Host "[RIESGO DE SEGURIDAD] Se encontraron paquetes NuGet con vulnerabilidades conocidas:" -ForegroundColor Red
                $vulnOut | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
                exit 1
            }
            
            Write-Host "[CADENA DE SUMINISTRO SEGURA] No se encontraron vulnerabilidades conocidas en los paquetes NuGet."
        '
        Descripcion  = "Utiliza la herramienta de .NET para escanear todos los paquetes NuGet (directos y transitivos) en busca de vulnerabilidades de seguridad reportadas."
    }
)

# 3. Ejecución de la Autopsia
$finalVerdict = 0
foreach ($specialist in $ForensicBoard) {
    Write-Host "--- [EXAMEN FORENSE: $($specialist.Area)] ---" -ForegroundColor Yellow
    Write-Host " Especialista: $($specialist.Especialista)" -ForegroundColor Cyan
    Write-Host " Protocolo:    $($specialist.Descripcion)" -ForegroundColor DarkGray

    $exitCode = 0
    try {
        $wrappedCmd = "try { `$null = chcp 65001 } catch {}; `$OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; `$ProgressPreference = 'SilentlyContinue';`n" + $specialist.Command
        $encodedCmd = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($wrappedCmd))
        & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encodedCmd
        $exitCode = $LASTEXITCODE
    } catch {
        Write-Host "[FALLO CATASTROFICO] El examen no pudo completarse: $($_.Exception.Message)" -ForegroundColor Red
        $exitCode = 255
    }

    if ($exitCode -eq 0) {
        Write-Host "[VEREDICTO] SANO / INTEGRO" -ForegroundColor Green
    } else {
        Write-Host "[VEREDICTO] PATOLOGIA DETECTADA (Exit Code: $exitCode)" -ForegroundColor Red
        $finalVerdict = 1
    }
    Write-Host ""
}

# 4. Dictamen Final
Write-Host "=========================================================" -ForegroundColor Magenta
Write-Host "           DICTAMEN FINAL DE LA AUTOPSIA                 " -ForegroundColor Magenta
Write-Host "=========================================================" -ForegroundColor Magenta

if ($finalVerdict -eq 0) {
    Write-Host "[APROBADO] Integridad estructural, documental y dependencias SOLIDAS." -ForegroundColor Green
} else {
    Write-Host "[RECHAZADO] Se encontraron patologias en la inspeccion forense." -ForegroundColor Red
    Write-Host "Consulte los detalles para aplicar correcciones." -ForegroundColor Yellow
}

exit $finalVerdict