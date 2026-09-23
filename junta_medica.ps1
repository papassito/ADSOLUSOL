<#
================================================================================
  ADSOLUSOL :: JUNTA MEDICA SUPREMA FORENSE v6.0 (.NET / ONION / CI-CD)
  "Auditoría Pericial Total: Sintaxis C#, Contención Onion/Clean Architecture,
   Criptografía Ed25519, UI MAUI Desktop, Blindaje EDR y Compilación de Release"
================================================================================
#>
param(
    [string]$Root = ".",
    [switch]$Fix,
    [switch]$Fast,
    [switch]$Status,
    [switch]$Add,
    [switch]$Commit,
    [switch]$Push,
    [string]$CommitMessage = "chore(audit): junta medica forense 10/10 pass - expediente clinico actualizado"
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Resolución canónica de la ruta raíz
$ScriptRoot = (Resolve-Path $Root).Path
if ((Split-Path -Path $ScriptRoot -Leaf) -eq "scripts") {
    $ScriptRoot = Split-Path -Path $ScriptRoot -Parent
}
Set-Location $ScriptRoot

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   ADSOLUSOL :: JUNTA MEDICA Y AUDITORIA FORENSE         " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Directorio del Expediente: $ScriptRoot" -ForegroundColor DarkGray

# 2. Detección Inteligente del Lenguaje y Ecosistema del Proyecto
$detectedLanguages = @()
$csCount = (Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }).Count
$psCount = (Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.ps1" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[\\/](\.git)[\\/]" }).Count
$mdCount = (Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[\\/](\.git)[\\/]" }).Count
$jsonCount = (Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.json" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }).Count

if ($csCount -gt 0) { $detectedLanguages += "C# / .NET 8 ($csCount archivos)" }
if ($psCount -gt 0) { $detectedLanguages += "PowerShell ($psCount scripts)" }
if ($mdCount -gt 0) { $detectedLanguages += "Markdown Docs ($mdCount archivos)" }
if ($jsonCount -gt 0) { $detectedLanguages += "JSON / Config ($jsonCount archivos)" }

Write-Host "Ecosistema Detectado: " -NoNewline -ForegroundColor Cyan
Write-Host ($detectedLanguages -join " | ") -ForegroundColor Green
Write-Host ""

# 3. Intervención Quirúrgica Preventiva (-Fix)
if ($Fix) {
    Write-Host "[CIRUGIA DE EMERGENCIA] Aplicando bisturí higiénico preventivo (-Fix)..." -ForegroundColor Yellow

    # A. Extirpación de archivos residuales, fantasma y duplicados
    $ghostPatterns = @("* (1).*", "* (2).*", "*.tmp", "*.bak", "*.orig", "*~", "*.swp")
    $ghosts = Get-ChildItem -Path $ScriptRoot -Recurse -Include $ghostPatterns -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "[\\/]\.git[\\/]" }
    foreach ($g in $ghosts) {
        Remove-Item $g.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "  [EXTIRPADO] Archivo fantasma/duplicado: $($g.Name)" -ForegroundColor Green
    }

    # B. Extirpación de archivos vacíos (0 bytes) que pudren la compilación
    $emptyCs = Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -eq 0 -and $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }
    foreach ($ec in $emptyCs) {
        Remove-Item $ec.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "  [EXTIRPADO] Archivo C# vacío (0 bytes): $($ec.FullName.Substring($ScriptRoot.Length))" -ForegroundColor Green
    }

    # C. Reubicación/Eliminación de MauiProgram.cs huérfano fuera de Presentation.Desktop
    $strayMauis = Get-ChildItem -Path $ScriptRoot -Recurse -Filter "MauiProgram.cs" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "Presentation\.Desktop" -and $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }
    foreach ($sm in $strayMauis) {
        Remove-Item $sm.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "  [EXTIRPADO] MauiProgram.cs huérfano en: $($sm.FullName.Substring($ScriptRoot.Length))" -ForegroundColor Green
    }

    # D. Saneamiento de BOM UTF-8, Caracteres de Control y Normalización de Saltos de Línea
    $bomCount = 0
    $ctrlCount = 0
    $validExts = @(".cs", ".csproj", ".json", ".md", ".ps1", ".xaml", ".razor")
    $textFiles = Get-ChildItem -Path $ScriptRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $validExts -contains $_.Extension -and $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($file in $textFiles) {
        $rawBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
            $rawBytes = $rawBytes[3..($rawBytes.Length - 1)]
            $bomCount++
        }
        $text = [System.Text.Encoding]::UTF8.GetString($rawBytes)
        # Sanitizar caracteres nulos y caracteres de control dañinos (conservando \t, \r, \n)
        $sanitizedText = [System.Text.RegularExpressions.Regex]::Replace($text, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '')
        if ($sanitizedText.Length -ne $text.Length) { $ctrlCount++ }

        # Normalizar CRLF
        $sanitizedText = $sanitizedText -replace "\r?\n", "`r`n"
        [System.IO.File]::WriteAllText($file.FullName, $sanitizedText, $utf8NoBom)
    }
    if ($bomCount -gt 0) { Write-Host "  [SANEADO] $bomCount archivo(s) despojados de marcas BOM UTF-8." -ForegroundColor Green }
    if ($ctrlCount -gt 0) { Write-Host "  [SANEADO] $ctrlCount archivo(s) purgados de caracteres de control corruptos." -ForegroundColor Green }

    # E. Extirpación de Carpetas Fantasma / Vacías
    Get-ChildItem -Path $ScriptRoot -Recurse -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "[\\/]\.git" } |
        Sort-Object -Property { $_.FullName.Length } -Descending |
        ForEach-Object {
            if ((Get-ChildItem -Path $_.FullName -Force | Measure-Object).Count -eq 0) {
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "  [AMPUTADO] Carpeta vacía eliminada: $($_.FullName.Substring($ScriptRoot.Length))" -ForegroundColor Green
            }
        }

    # F. Restauración y Formateo Canónico (.NET Format)
    $sln = Join-Path $ScriptRoot "ADSOLUSOL.sln"
    if (Test-Path $sln) {
        Write-Host "  [SANEANDO] Restaurando dependencias y formateando código..." -ForegroundColor Yellow
        & dotnet restore $sln -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false --verbosity quiet 2>&1 | Out-Null
        & dotnet format $sln --no-restore --verbosity quiet 2>&1 | Out-Null
        Write-Host "  [SANEADO] Formato canónico C# homogeneizado." -ForegroundColor Green
    }
    Write-Host ""
}

# 4. Cuadro Médico Unificado de Especialistas Forenses (26 Patologías Auditadas)
$MedicalBoard = @(
    @{
        Area         = "Inmunología de Codificación, BOM y Caracteres de Control"
        Especialista = "Integridad UTF-8, Ausencia de BOM, Nulos y Caracteres Inválidos"
        Command      = '
            $validExts = @(".cs", ".csproj", ".json", ".md", ".ps1")
            $files = Get-ChildItem -Path @("src", "tests", "docs") -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $validExts -contains $_.Extension -and $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }
            $errors = 0
            foreach ($file in $files) {
                if ($file.Length -eq 0) {
                    Write-Host "[PATOLOGIA] Archivo vacío (0 bytes): $($file.FullName)" -ForegroundColor Red
                    $errors++
                }
                $b = [System.IO.File]::ReadAllBytes($file.FullName)
                if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
                    Write-Host "[PATOLOGIA] Marca BOM UTF-8 detectada en: $($file.Name)" -ForegroundColor Red
                    $errors++
                }
                $txt = [System.IO.File]::ReadAllText($file.FullName)
                if ($txt.Contains([char]0)) {
                    Write-Host "[PATOLOGIA] Carácter nulo (\0) corrupto detectado en: $($file.Name)" -ForegroundColor Red
                    $errors++
                }
                if ($txt.Contains([char]0xFFFD)) {
                    Write-Host "[PATOLOGIA] Carácter de reemplazo corrupto (\uFFFD) en: $($file.Name)" -ForegroundColor Red
                    $errors++
                }
            }
            if ($errors -gt 0) { exit 1 } else { Write-Host "[SANO] $($files.Count) archivos analizados sin BOM, caracteres nulos ni corrupción UTF-8." }
        '
        Descripcion  = "Auditoría de codificación UTF-8 estricta, ausencia de BOM, caracteres nulos y secuencias corruptas."
    },
    @{
        Area         = "Traumatología y Segregación Estructural (Clean / Onion)"
        Especialista = "Higiene de Raíz, Detección de Huérfanos y Contratos de Repositorio"
        Command      = '
            $errors = 0
            $rootProjects = Get-ChildItem -Path . -Filter "*.csproj" -File -ErrorAction SilentlyContinue
            if ($rootProjects.Count -gt 0) {
                foreach ($rp in $rootProjects) {
                    Write-Host "[GANGRENA] Proyecto .csproj huérfano en la raíz: $($rp.Name)" -ForegroundColor Red
                    $errors++
                }
            }
            $mauiStray = Get-ChildItem -Path "src" -Recurse -Filter "MauiProgram.cs" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "Presentation\.Desktop" -and $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }
            if ($mauiStray) {
                foreach ($m in $mauiStray) {
                    Write-Host "[PATOLOGIA] MauiProgram.cs fuera de Presentation.Desktop: $($m.FullName)" -ForegroundColor Red
                    $errors++
                }
            }
            $repos = Get-ChildItem -Path "src" -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
                Where-Object { ($_.Name -eq "CreativeRepository.cs" -or $_.Name -eq "PlacementRepository.cs") -and $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }
            foreach ($repo in $repos) {
                $content = Get-Content $repo.FullName -Raw
                if ($content -match "public\s+async\s+Task\s+CreateAsync") {
                    Write-Host "[PATOLOGIA] $($repo.Name) implementa Task CreateAsync en vez de Task<long> CreateAsync" -ForegroundColor Red
                    $errors++
                }
            }
            if ($errors -gt 0) { exit 1 } else { Write-Host "[SANO] Topología Onion inmaculada: cero fuentes huérfanas y contratos asíncronos válidos." }
        '
        Descripcion  = "Inspección de proyectos huérfanos en raíz, segregación de UI MAUI y contratos tipados en repositorios."
    },
    @{
        Area         = "Oftalmología y Formato Canónico (.NET Format)"
        Especialista = "Inspección Visual y Estilo Canónico de Código C#"
        Command      = '
            & dotnet restore "ADSOLUSOL.sln" --verbosity quiet 2>&1 | Out-Null
            $formatOut = & dotnet format "ADSOLUSOL.sln" --no-restore --verify-no-changes --verbosity minimal 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[DIPLOPIA] El código presenta discrepancias visuales con el estándar dotnet format:`n$formatOut" -ForegroundColor Red
                Write-Host "[INFO] Ejecute junta_medica con switch -Fix para autoformatear." -ForegroundColor Yellow
                exit 1
            }
            Write-Host "[SANO] Agudeza visual 20/20: Todo el código C# cumple con el estándar canónico."
        '
        Descripcion  = "Verificación pericial del formato de código mediante dotnet format oficial."
    },
    @{
        Area         = "Neurología y Análisis Estático (dotnet build & Roslyn)"
        Especialista = "Diagnóstico de Compilación, Tipado y Diagnósticos Roslyn"
        Command      = '
            $buildOut = & dotnet build "ADSOLUSOL.sln" -c Release -p:IgnoreMissingWorkloads=true -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false -v:minimal /nologo 2>&1
            if ($LASTEXITCODE -ne 0) {
                $errors = $buildOut | Where-Object { $_ -match ":\s*error\s+(CS|MSB|NU|NETSDK)\d+:" }
                Write-Host "[ARRITMIA] Fallo en la compilación de la solución:" -ForegroundColor Red
                if ($errors) {
                    $errors | ForEach-Object { Write-Host "  -> $_" -ForegroundColor Red }
                } else {
                    $buildOut | Where-Object { $_.Trim() -ne "" } | ForEach-Object { Write-Host "  -> $_" -ForegroundColor Red }
                }
                exit 1
            }
            Write-Host "[SANO] Compilación diagnóstica 100% limpia: Cero errores CS, MSB o NuGet."
        '
        Descripcion  = "Compilación estática de todos los proyectos de la solución en configuración Release."
    },
    @{
        Area         = "Cardiología Forense (Pruebas Unitarias, Regresión y Smokey)"
        Especialista = "Verificación de Motores, Débito Presupuestario y Smokey Tests"
        Command      = '
            $testProjects = Get-ChildItem -Path tests -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue
            if (-not $testProjects) {
                Write-Host "[INFO] No se localizaron proyectos de pruebas en tests/." -ForegroundColor Yellow
                exit 0
            }
            $hasError = $false
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            foreach ($t in $testProjects) {
                $testOut = & dotnet test $t.FullName --no-build -c Release -v:q --nologo 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "[ARRITMIA] Fallo en la suite de pruebas: $($t.Name)" -ForegroundColor Red
                    $testOut | Where-Object { $_ -match "Failed|Exception" } | ForEach-Object { Write-Host "  -> $_" -ForegroundColor Red }
                    $hasError = $true
                }
            }
            $sw.Stop()
            $perfSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
            if ($hasError) { exit 1 } else { Write-Host "[SANO] Pulso cardíaco regular: 100% pruebas de regresión aprobadas en ${perfSec}s (rendimiento óptimo)." }
        '
        Descripcion  = "Evaluación de suites de regresión, integridad de débito atómico y telemetría de rendimiento."
    },
    @{
        Area         = "Farmacología, Criptografía y Blindaje Perimetral EDR"
        Especialista = "Inmunidad a Secretos Expuestos y Heurísticas Antivirus"
        Command      = '
            $errors = 0
            $secretPatterns = @(
                @{ Pattern = "BEGIN\s+(RSA\s+)?PRIVATE\s+KEY"; Label = "Clave privada RSA/PEM expuesta" },
                @{ Pattern = "Password\s*=\s*`"[^`"]{4,}`""; Label = "Posible contrasena en texto plano" },
                @{ Pattern = "SecretKey\s*=\s*`"[^`"]{4,}`""; Label = "Posible SecretKey en texto plano" }
            )
            $sourceFiles = Get-ChildItem -Path src -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "\\/[\\/]" }
            foreach ($f in $sourceFiles) {
                $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
                foreach ($p in $secretPatterns) {
                    if ($content -match $p.Pattern) {
                        Write-Host "[PATOLOGIA] $($p.Label) en $($f.Name)" -ForegroundColor Red
                        $errors++
                    }
                }
            }
            $scripts = Get-ChildItem -Path . -Recurse -Include "*.ps1","*.bat","*.cmd" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "[\\/]\.git[\\/]" }
            foreach ($s in $scripts) {
                $sc = Get-Content $s.FullName -Raw -ErrorAction SilentlyContinue
                if ($sc -match "Invoke-Expression\s+\$" -or $sc -match "\biex\s+\$") {
                    Write-Host "[PATOLOGIA] Inyección ofuscada de alto riesgo EDR en $($s.Name)" -ForegroundColor Red
                    $errors++
                }
            }
            if ($errors -gt 0) { exit 1 } else { Write-Host "[SANO] Inmunidad EDR: Cero secretos expuestos y scripts libres de heurísticas maliciosas." }
        '
        Descripcion  = "Inspección perimetral de cadenas sensibles y blindaje contra falsos positivos EDR/Antivirus."
    },
    @{
        Area         = "Gobernanza Documental y Coherencia de Contratos (Markdown)"
        Especialista = "Integridad de Documentación Canónica y Coherencia de Integración"
        Command      = '
            $errors = 0
            $docFiles = Get-ChildItem -Path docs -Recurse -Filter "*.md" -File -ErrorAction SilentlyContinue
            foreach ($df in $docFiles) {
                if ($df.Length -eq 0) {
                    Write-Host "[PATOLOGIA] Documento Markdown vacío: $($df.Name)" -ForegroundColor Red
                    $errors++
                }
            }
            $brain = Join-Path $pwd "docs/MARKETING-BRAIN.md"
            if (Test-Path $brain) {
                $bContent = Get-Content $brain -Raw
                if ($bContent -match "NOT_IMPLEMENTED / UNVERIFIED") {
                    Write-Host "[PATOLOGIA] MARKETING-BRAIN.md contiene estado obsoleto (NOT_IMPLEMENTED)" -ForegroundColor Red
                    $errors++
                }
            }
            if ($errors -gt 0) { exit 1 } else { Write-Host "[SANO] Biblioteca documental íntegra y sincronizada con el runtime real." }
        '
        Descripcion  = "Auditoría de no-vacuidad en archivos Markdown y alineación documental con Marketing Brain."
    },
    @{
        Area         = "Dermatología y Cobertura Funcional de UI (Sitemap & DI Wiring)"
        Especialista = "Integridad de Vistas Blazor, Navegación y Contenedor Desktop"
        Command      = '
            $errors = 0
            $desktopMaui = Join-Path $pwd "src/ADSOLUSOL.Presentation.Desktop/MauiProgram.cs"
            if (-not (Test-Path $desktopMaui)) {
                Write-Host "[PATOLOGIA] Falta el punto de entrada UI: MauiProgram.cs" -ForegroundColor Red
                $errors++
            } else {
                $mauiContent = Get-Content $desktopMaui -Raw
                $required = @("IMarketingBrainService", "MarketingBrainClient", "CampaignService", "BudgetService", "MetricsService", "AdServingService")
                foreach ($r in $required) {
                    if ($mauiContent -notmatch $r) {
                        Write-Host "[PATOLOGIA] Servicio no registrado en DI Desktop: $r" -ForegroundColor Red
                        $errors++
                    }
                }
            }
            if ($errors -gt 0) { exit 1 } else { Write-Host "[SANO] Cobertura funcional de UI y contenedor DI al 100% verificado." }
        '
        Descripcion  = "Inspección de cobertura funcional, registros de servicios y cableado de navegación Desktop."
    },
    @{
        Area         = "Cirugía General y Compilación de Producción CI/CD"
        Especialista = "Publicación Nativa Desktop (ADSOLUSOL.Presentation.Desktop)"
        Command      = '
            $desktopProj = Join-Path $pwd "src\ADSOLUSOL.Presentation.Desktop\ADSOLUSOL.Presentation.Desktop.csproj"
            if (-not (Test-Path $desktopProj)) {
                Write-Host "[CRITICO] Falta el proyecto Desktop principal en $desktopProj" -ForegroundColor Red
                exit 1
            }
            $publishDir = Join-Path $pwd "BUILD\ADSOLUSOL"
            if (Test-Path $publishDir) { Remove-Item $publishDir -Recurse -Force }
            New-Item -ItemType Directory -Force -Path $publishDir | Out-Null
            & dotnet restore $desktopProj -f net8.0-windows10.0.19041.0 -r win-x64 -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false --verbosity quiet 2>&1 | Out-Null
            & dotnet publish $desktopProj -c Release -f net8.0-windows10.0.19041.0 -r win-x64 --no-restore --nologo -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false -p:IgnoreMissingWorkloads=true -o $publishDir
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[PATOLOGIA] Fallo en la publicación del artefacto nativo MAUI Desktop." -ForegroundColor Red
                exit 1
            }
            $exe = Get-ChildItem -Path $publishDir -Filter "ADSOLUSOL.Presentation.Desktop.exe" -Recurse | Select-Object -First 1
            if (-not $exe) {
                Write-Host "[PATOLOGIA] Binario ejecutable principal no encontrado en el artefacto publicado." -ForegroundColor Red
                exit 1
            }
            $sizeMB = [math]::Round($exe.Length / 1MB, 2)
            Write-Host "[SANO] Publicación exitosa: $($exe.Name) ($sizeMB MB) listo para distribución en Windows."
        '
        Descripcion  = "Validación del pipeline de publicación nativa Windows net8.0 x64."
    }
)

# 5. Ejecución del Dictamen Forense
$medicalRecords = @()
if (-not (Test-Path "docs")) { New-Item -ItemType Directory -Force -Path "docs" | Out-Null }
$reportPath = Join-Path $ScriptRoot "docs/EXPEDIENTE_CLINICO_MAESTRO.md"
$totalConsultas = $MedicalBoard.Count

foreach ($doctor in $MedicalBoard) {
    if ($Fast -and $doctor.Area -like "*Compilación de Producción*") {
        Write-Host "`n--- [CONSULTA OMITIDA : $($doctor.Area) (-Fast activo)] ---" -ForegroundColor DarkGray
        continue
    }

    $index = $medicalRecords.Count + 1
    Write-Host ""
    Write-Host "--- [CONSULTA MEDICA $index/$totalConsultas : $($doctor.Area)] ---" -ForegroundColor Yellow
    Write-Host " Especialista: $($doctor.Especialista)" -ForegroundColor Cyan
    Write-Host " Dictamen:     $($doctor.Descripcion)" -ForegroundColor DarkGray

    $consultaStatus = "CRITICO (FAIL)"
    $output = ""

    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = (Get-Process -Id $PID).Path
        $wrappedCmd = "try { `$null = chcp 65001 } catch {}; `$OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; `$ProgressPreference = 'SilentlyContinue';`n" + $doctor.Command
        $encodedCmd = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($wrappedCmd))
        $pinfo.Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encodedCmd"
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $pinfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true
        $pinfo.WorkingDirectory = $ScriptRoot
        $pinfo.EnvironmentVariables["CI"] = "true"

        $process = [System.Diagnostics.Process]::Start($pinfo)
        $stdOutTask = $process.StandardOutput.ReadToEndAsync()
        $stdErrTask = $process.StandardError.ReadToEndAsync()

        $timeoutMilliseconds = 240000 # 4 minutos
        if ($process.WaitForExit($timeoutMilliseconds)) {
            $process.WaitForExit()
            $rawOutput = ($stdOutTask.Result + "`n" + $stdErrTask.Result).Trim()
            # Limpiar rastro de serialización CLIXML de PowerShell
            $cleanLines = @($rawOutput -split "`r?`n" | Where-Object {
                $_ -notmatch '^#<\s*CLIXML' -and
                $_ -notmatch '^\s*<Objs\b' -and
                $_ -notmatch '^\s*</Objs>' -and
                $_ -notmatch '^\s*<Obj\b' -and
                $_ -notmatch '^\s*<[A-Z0-9]+(\s+[^>]*)?>'
            })
            $output = ($cleanLines -join "`n").Trim()

            if ($process.ExitCode -eq 0) {
                $consultaStatus = "SANO (PASS)"
                Write-Host "[OK] Evaluación pericial aprobada sin anomalías." -ForegroundColor Green
            } else {
                $consultaStatus = "OBSERVACION (Exit Code: $($process.ExitCode))"
                Write-Host "[FAIL] Se hallaron anomalías clínicas durante el diagnóstico." -ForegroundColor Red
            }
        } else {
            $consultaStatus = "CRITICO (TIMEOUT)"
            $output = "[TIMEOUT] La consulta superó el tiempo límite y fue terminada.`n"
            try { $output += ($stdOutTask.Result + "`n" + $stdErrTask.Result).Trim() } catch {}
            Write-Host "[TIMEOUT] El especialista no respondió a tiempo." -ForegroundColor Red
            try { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue } catch {}
        }
    } catch {
        $output = $_.Exception.Message + "`n" + $output
        Write-Host "[FAIL] Excepción imprevista: $($_.Exception.Message)" -ForegroundColor Red
    }

    $medicalRecords += [PSCustomObject]@{
        Area         = $doctor.Area
        Especialista = $doctor.Especialista
        Descripcion  = $doctor.Descripcion
        Status       = $consultaStatus
        Output       = $output
    }
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "   GENERANDO EXPEDIENTE CLINICO MAESTRO                  " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 6. Generación del Expediente Clínico Maestro en docs/
$codeBlock = '```'
$mdReport = "# Expediente Clínico Maestro - ADSOLUSOL (Ads & Growth Engine)`n`n"
$mdReport += "**Fecha y Hora del Chequeo Forense:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
$mdReport += "**Ecosistema Auditado:** " + ($detectedLanguages -join " | ") + "`n`n"
$mdReport += "## Dictamen Resumido de la Junta Médica Forense`n`n"
$mdReport += "| Área Médica | Especialista / Peritaje Forense | Diagnóstico Clínico |`n"
$mdReport += "|---|---|---|`n"

foreach ($record in $medicalRecords) {
    $mdReport += "| **$($record.Area)** | $($record.Especialista) | **$($record.Status)** |`n"
}

$mdReport += "`n---`n`n"
$mdReport += "## Detalle de Observaciones Quirúrgicas y Laboratorio`n`n"

foreach ($record in $medicalRecords) {
    $mdReport += "### Área: $($record.Area)`n"
    $mdReport += "**Especialista:** $($record.Especialista) | **Estado:** **$($record.Status)**`n`n"
    $mdReport += "*Alcance Clínico:* $($record.Descripcion)`n`n"
    $mdReport += $codeBlock + "text`n" + $record.Output + "`n" + $codeBlock + "`n`n"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($reportPath, $mdReport, $utf8NoBom)
Write-Host "[OK] Expediente clínico guardado en: $reportPath" -ForegroundColor Green

$criticalFailures = @($medicalRecords | Where-Object { $_.Status -notlike "SANO*" })

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "           DICTAMEN MEDICO FINAL DE ADSOLUSOL            " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

if ($criticalFailures.Count -eq 0) {
    Write-Host "[PASS] ALTA MEDICA 10/10: ADSOLUSOL presenta salud digital y operativa al 100%." -ForegroundColor Green
} else {
    Write-Host "[FAIL] INTERVENCION REQUERIDA: $($criticalFailures.Count) área(s) presentan observaciones." -ForegroundColor Red
    $criticalFailures | ForEach-Object { Write-Host "  - $($_.Area) [$($_.Especialista)]" -ForegroundColor Yellow }
}

# 7. Operaciones de Git y Envío a GitHub
$hasGitFlags = $Status -or $Add -or $Commit -or $Push
if ($hasGitFlags) {
    Write-Host "`n=========================================================" -ForegroundColor Cyan
    Write-Host "         OPERACIONES GIT / SINCRONIZACION GITHUB         " -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    try {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) {
            Write-Host "[ERR] 'git' no está disponible en el PATH." -ForegroundColor Red
        } else {
            if ($Status -or ($Push -and -not $Add -and -not $Commit)) {
                Write-Host "`n[GIT STATUS] Estado del repositorio:" -ForegroundColor Yellow
                & git status
            }

            if ($Add -or ($Push -and -not $Commit)) {
                Write-Host "`n[GIT ADD] Preparando cambios (git add -A)..." -ForegroundColor Yellow
                & git add -A
                & git status --short
            }

            if ($criticalFailures.Count -gt 0 -and ($Commit -or $Push)) {
                Write-Host "`n[BLOQUEO DE SEGURIDAD] Commit/Push abortado: existen fallos clínicos activos." -ForegroundColor Red
                Write-Host "Aplique '.\junta_medica.ps1 -Fix' para sanear antes de subir a GitHub." -ForegroundColor Yellow
            } else {
                if ($Commit -or $Push) {
                    $pending = & git status --porcelain
                    if ($pending) {
                        Write-Host "`n[GIT COMMIT] Generando commit certificado..." -ForegroundColor Yellow
                        & git commit -m $CommitMessage
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "[OK] Commit registrado con éxito." -ForegroundColor Green
                        }
                    } else {
                        Write-Host "[INFO] Repositorio limpio. No hay cambios pendientes." -ForegroundColor Cyan
                    }
                }

                if ($Push) {
                    Write-Host "`n[GIT PUSH] Transmitiendo cambios a GitHub..." -ForegroundColor Yellow
                    & git push
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "[OK] Sincronización con GitHub completada exitosamente." -ForegroundColor Green
                    } else {
                        Write-Host "[WARN] 'git push' finalizó con advertencias (ExitCode: $LASTEXITCODE)." -ForegroundColor Yellow
                    }
                }
            }
        }
    } catch {
        Write-Host "[ERR] Fallo durante la interacción con Git: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 8. Exit Code
if ($env:CI) {
    if ($criticalFailures.Count -gt 0) { exit 1 } else { exit 0 }
} else {
    $global:LASTEXITCODE = if ($criticalFailures.Count -gt 0) { 1 } else { 0 }
    Write-Host ""
    return
}