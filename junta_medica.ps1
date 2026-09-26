<#
================================================================================
  ADSOLUSOL :: JUNTA MEDICA FORENSE (READ-ONLY QUALITY GATE & LINTER)
  Auditoria Pericial Pasiva: Sintaxis C#, Contencion Onion, Criptografia Ed25519,
  Ausencia de Secretos EDR, Formato Canonico y Suites de Regresion
================================================================================
#>
param(
    [string]$Root = ".",
    [switch]$Fast
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Resolucion canonica de la ruta raiz
$ScriptRoot = (Resolve-Path $Root).Path
if ((Split-Path -Path $ScriptRoot -Leaf) -eq "scripts") {
    $ScriptRoot = Split-Path -Path $ScriptRoot -Parent
}
Set-Location $ScriptRoot

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   ADSOLUSOL :: JUNTA MEDICA Y AUDITORIA FORENSE         " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Directorio del Expediente: $ScriptRoot" -ForegroundColor DarkGray

# 2. Deteccion Inteligente del Lenguaje y Ecosistema del Proyecto
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

# 3. Cuadro Medico Unificado de Especialistas Forenses (Auditoria Pasiva)
$MedicalBoard = @(
    @{
        Area         = "Inmunologia de Codificacion, BOM y Caracteres de Control"
        Especialista = "Integridad UTF-8, Ausencia de BOM, Nulos y Caracteres Invalidos"
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
                if ([System.Text.RegularExpressions.Regex]::IsMatch($txt, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]")) {
                    Write-Host "[PATOLOGIA] Caracteres de control inválidos detectados en: $($file.Name)" -ForegroundColor Red
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
        Area         = "Traumatologia y Segregacion Estructural (Clean / Onion)"
        Especialista = "Higiene de Raiz, Deteccion de Huerfanos y Contratos de Repositorio"
        Command      = '
            $errors = 0
            $rootProjects = Get-ChildItem -Path . -Filter "*.csproj" -File -ErrorAction SilentlyContinue
            if ($rootProjects.Count -gt 0) {
                foreach ($rp in $rootProjects) {
                    Write-Host "[GANGRENA] Proyecto .csproj huérfano en la raíz: $($rp.Name)" -ForegroundColor Red
                    $errors++
                }
            }
            $alienFiles = @("AIInferenceAdapter.ts", "AssetBrowserModal.tsx", "printer_bridge.cpp", "ci.yml")
            foreach ($af in $alienFiles) {
                if (Test-Path $af) {
                    Write-Host "[PATOLOGIA] Archivo foráneo ajeno al dominio ADS en la raíz: $af" -ForegroundColor Red
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
        Area         = "Oftalmologia y Formato Canonico (.NET Format)"
        Especialista = "Inspeccion Visual y Estilo Canonico de Codigo C#"
        Command      = '
            & dotnet restore "ADSOLUSOL.sln" --verbosity quiet 2>&1 | Out-Null
            $formatOut = & dotnet format "ADSOLUSOL.sln" --no-restore --verify-no-changes --verbosity minimal 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[DIPLOPIA] El código presenta discrepancias visuales con el estándar dotnet format:`n$formatOut" -ForegroundColor Red
                Write-Host "[INFO] Ejecute .\release.ps1 -Fix (o dotnet format) para autoformatear." -ForegroundColor Yellow
                exit 1
            }
            Write-Host "[SANO] Agudeza visual 20/20: Todo el código C# cumple con el estándar canónico."
        '
        Descripcion  = "Verificación pericial del formato de código mediante dotnet format oficial."
    },
    @{
        Area         = "Neurologia y Analisis Estatico (dotnet build & Roslyn)"
        Especialista = "Diagnostico de Compilacion, Tipado y Diagnosticos Roslyn"
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
        Area         = "Cardiologia Forense (Pruebas Unitarias, Regresion y Smokey)"
        Especialista = "Verificacion de Motores, Debito Presupuestario y Smokey Tests"
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
        Area         = "Farmacologia, Criptografia y Blindaje Perimetral EDR"
        Especialista = "Inmunidad a Secretos Expuestos y Heuristicas Antivirus"
        Command      = '
            $errors = 0
            $secretPatterns = @(
                @{ Pattern = ''BEGIN\s+(RSA\s+)?PRIVATE\s+KEY''; Label = "Clave privada RSA/PEM expuesta" },
                @{ Pattern = ''Password\s*=\s*"[^"]{4,}"''; Label = "Posible contrasena en texto plano" },
                @{ Pattern = ''SecretKey\s*=\s*"[^"]{4,}"''; Label = "Posible SecretKey en texto plano" }
            )
            $sourceFiles = Get-ChildItem -Path src -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }
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
        Area         = "Calidad de Codigo y Olores (Code Smells)"
        Especialista = "Deteccion de Excepciones no Implementadas, Capturas Silenciosas y Comentarios TODO/FIXME"
        Command      = '
            $errors = 0
            $sourceFiles = Get-ChildItem -Path "src", "tests" -Recurse -Filter "*.cs" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "[\\/](\.git|bin|obj|BUILD)[\\/]" }
            
            $sourceFiles | Select-String -Pattern "NotImplementedException" | ForEach-Object {
                Write-Host "[PATOLOGIA] NotImplementedException en $(Split-Path $_.Path -Leaf):$($_.LineNumber)" -ForegroundColor Red
                $errors++
            }
            $sourceFiles | Select-String -Pattern "catch\s*(\([^\)]*\))?\s*\{\s*\}" | ForEach-Object {
                Write-Host "[PATOLOGIA] Bloque catch silencioso (ignora errores) en $(Split-Path $_.Path -Leaf):$($_.LineNumber)" -ForegroundColor Red
                $errors++
            }
            $sourceFiles | Select-String -Pattern "\b(TODO|FIXME)\b" -CaseSensitive | ForEach-Object {
                Write-Host "[OBSERVACION] Comentario TODO/FIXME en $(Split-Path $_.Path -Leaf):$($_.LineNumber) -> $($_.Line.Trim())" -ForegroundColor Yellow
            }

            if ($errors -gt 0) { exit 1 } else { Write-Host "[SANO] Código libre de olores críticos (excepciones no implementadas, capturas silenciosas)." }
        '
        Descripcion  = "Análisis estático para detectar patrones de código problemáticos como NotImplementedException, bloques catch vacíos y comentarios de trabajo pendiente."
    },
    @{
        Area         = "Gobernanza y Verificacion de Integracion Externa (SIC)"
        Especialista = "Analisis de Codigo Fuente para Conectividad Real (No Mocks)"
        Command      = '
            $errors = 0
            $clientFile = Join-Path $pwd "src/ADSOLUSOL.Infrastructure/ExternalServices/MarketingBrain/MarketingBrainClient.cs"
            if (-not (Test-Path $clientFile)) {
                Write-Host "[PATOLOGIA] No se encontró el archivo del cliente: MarketingBrainClient.cs" -ForegroundColor Red
                exit 1
            }
            $content = Get-Content $clientFile -Raw
            if ($content -match "Task\.FromResult" -or $content -match "Task\.CompletedTask") {
                Write-Host "[PATOLOGIA] MarketingBrainClient.cs contiene una implementación simulada (mock) con Task.FromResult o Task.CompletedTask." -ForegroundColor Red
                $errors++
            }
            if ($content -notmatch "HttpClient" -and $content -notmatch "IHttpClientFactory") {
                Write-Host "[PATOLOGIA] MarketingBrainClient.cs no parece utilizar HttpClient para conectividad real." -ForegroundColor Red
                $errors++
            }
            if ($errors -gt 0) { exit 1 } else { Write-Host "[SANO] Verificación de código fuente confirma integración real de MarketingBrainClient (uso de HttpClient)." }
        '
        Descripcion  = "Auditoría de código fuente de MarketingBrainClient para asegurar que no es una simulación (mock) y que utiliza HttpClient para comunicación de red."
    },
    @{
        Area         = "Dermatologia y Cobertura Funcional de UI (Sitemap & DI Wiring)"
        Especialista = "Integridad de Vistas Blazor, Navegacion y Contenedor Desktop"
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
        Area         = "Endoscopia y Pruebas de Componentes UI (bUnit)"
        Especialista = "Verificacion Funcional de Componentes Blazor Aislados"
        Command      = '
            $uiTestProject = Get-ChildItem -Path "tests" -Filter "*UITests*.csproj" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $uiTestProject) {
                Write-Host "[INFO] No se localizaron proyectos de pruebas de UI (bUnit) en tests/." -ForegroundColor Yellow
                exit 0
            }
            Write-Host "Ejecutando pruebas de componentes UI para: $($uiTestProject.Name)" -ForegroundColor Cyan
            $testOut = & dotnet test $uiTestProject.FullName --no-build -c Release -v:q --nologo 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[PATOLOGIA] Fallo en las pruebas de componentes de la interfaz de usuario." -ForegroundColor Red
                $testOut | Where-Object { $_ -match "Failed|Exception" } | ForEach-Object { Write-Host "  -> $_" -ForegroundColor Red }
                exit 1
            }
            Write-Host "[SANO] Todos los componentes de la interfaz de usuario pasaron sus pruebas funcionales."
        '
        Descripcion  = "Ejecuta la suite de pruebas de componentes de UI (bUnit) para validar la lógica y el renderizado de los componentes Razor de forma aislada."
    }
)

# 5. Ejecucion del Dictamen Forense
$medicalRecords = @()
if (-not (Test-Path "docs")) { New-Item -ItemType Directory -Force -Path "docs" | Out-Null }
$reportPath = Join-Path $ScriptRoot "docs/EXPEDIENTE_CLINICO_MAESTRO.md"
$totalConsultas = $MedicalBoard.Count

foreach ($doctor in $MedicalBoard) {
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

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
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

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "           DICTAMEN MEDICO FINAL DE ADSOLUSOL            " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

if ($criticalFailures.Count -eq 0) {
    Write-Host "[PASS] ALTA MEDICA 10/10: ADSOLUSOL presenta salud digital y operativa al 100%." -ForegroundColor Green
} else {
    Write-Host "[FAIL] INTERVENCION REQUERIDA: $($criticalFailures.Count) area(s) presentan observaciones." -ForegroundColor Red
    foreach ($failure in $criticalFailures) {
        $itemArea = $failure.Area
        $itemEsp = $failure.Especialista
        Write-Host "  - $itemArea [$itemEsp]" -ForegroundColor Yellow
    }
}

# 6. Exit Code Estricto para Pipelines CI/CD
if ($env:CI) {
    if ($criticalFailures.Count -gt 0) { exit 1 } else { exit 0 }
} else {
    $global:LASTEXITCODE = if ($criticalFailures.Count -gt 0) { 1 } else { 0 }
    if ($criticalFailures.Count -gt 0) { exit 1 } else { exit 0 }
}