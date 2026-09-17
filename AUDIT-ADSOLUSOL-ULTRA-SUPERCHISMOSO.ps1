$ErrorActionPreference = "Continue"
$Root = $PSScriptRoot
if (-not $Root) { $Root = (Get-Location).Path }

# --- State Tracking ---
$auditFailed = $false
$failureMessages = [System.Collections.Generic.List[string]]::new()

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL — AUDITORÍA Y CERTIFICACIÓN ULTRA SUPERCHISMOSA (v2.0)" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# --- 1. Locate .NET SDK ---
$dotnetExe = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source
if (-not $dotnetExe) {
    $failureMessages.Add("[CRITICAL] dotnet no encontrado en PATH.")
    $auditFailed = $true
} else {
    Write-Host "[✓] Ejecutable .NET detectado: $dotnetExe" -ForegroundColor Green
}

# --- 2. Locate Solution ---
$slnPath = Join-Path $Root "ADSOLUSOL.sln"
if (-not (Test-Path $slnPath)) {
    $failureMessages.Add("[CRITICAL] No se encontró el archivo 'ADSOLUSOL.sln' en la raíz.")
    $auditFailed = $true
} else {
     Write-Host "[✓] Solución bajo análisis: $slnPath`n" -ForegroundColor Green
}

# --- 3. Build Phase ---
if (-not $auditFailed) {
    Write-Host ">>> [FASE 1] Compilando la solución para análisis de errores..." -ForegroundColor Yellow
    $buildOut = & $dotnetExe build $slnPath --nologo 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        $auditFailed = $true
        $failureMessages.Add("[FAIL] Errores de compilación detectados.")
        
        # Detailed C# error parsing
        $errorRegex = '^(?<file>.*?\.cs)\((?<line>\d+),(?<col>\d+)\):\s+error\s+(?<code>CS\d+):\s+(?<msg>.*)$'
        $csErrors = $buildOut | Where-Object { $_ -match $errorRegex } | ForEach-Object {
            [PSCustomObject]@{
                Archivo = $Matches['file']
                Linea   = $Matches['line']
                Codigo  = $Matches['code']
                Mensaje = $Matches['msg'].Trim()
            }
        }

        if ($csErrors.Count -gt 0) {
            $grouped = $csErrors | Group-Object Archivo
            foreach ($group in $grouped) {
                $failureMessages.Add("`n📄 ARCHIVO: $($group.Name)")
                foreach ($err in $group.Group) {
                    $failureMessages.Add("   ├── Línea $($err.Linea): [$($err.Codigo)] $($err.Mensaje)")
                }
            }
        } else {
            # Fallback for non-CS errors (e.g., MSBuild)
            $failureMessages.Add("`n[!] No se detectaron errores de C# específicos. El fallo puede ser de MSBuild o de configuración.")
            $failureMessages.Add("Salida cruda del compilador:")
            $failureMessages.AddRange($buildOut)
        }
    } else {
        Write-Host "[PASS] Compilación exitosa (0 Errores)." -ForegroundColor Green
    }
}

# --- 4. Test Phase ---
if (-not $auditFailed) {
    Write-Host "`n>>> [FASE 2] Buscando y ejecutando proyectos de pruebas..." -ForegroundColor Yellow
    $testProjects = Get-ChildItem -Path $Root -Filter "*Test*.csproj" -Recurse

    if (-not $testProjects) {
        Write-Host "[INFO] No se localizaron proyectos de prueba. Omitiendo fase." -ForegroundColor Gray
    } else {
        foreach ($testProj in $testProjects) {
            Write-Host "`n📌 Ejecutando Suite: $($testProj.Name)" -ForegroundColor Cyan
            $testOut = & $dotnetExe test "$($testProj.FullName)" --no-build --nologo -v:q 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                $auditFailed = $true
                $failureMessages.Add("[FAIL] Fallaron pruebas en la suite: $($testProj.Name)")
                $failureMessages.AddRange($testOut | Where-Object { $_ -match "Failed|Error|Exception|Assert" })
            } else {
                $passCount = ($testOut | Select-String -Pattern "Passed!").Count
                Write-Host "  [✓] Pruebas ejecutadas correctamente (Pasaron: $passCount)." -ForegroundColor Green
            }
        }
    }
}

# --- 5. Final Report ---
Write-Host "`n==============================================================================" -ForegroundColor Cyan
Write-Host " RESULTADO DE LA AUDITORÍA" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

if ($auditFailed) {
    Write-Host "[FAIL] La auditoría ha fallado. Resumen de problemas:" -ForegroundColor Red
    foreach($msg in $failureMessages) {
        Write-Host $msg -ForegroundColor Red
    }
    Write-Host "`nGATE RESULT: FAIL" -ForegroundColor Red
    if (-not $env:CI) { # Don't terminate interactive sessions, but set exit code for scripts
        $host.SetShouldExit(1)
    } else {
        exit 1 # In CI environments, a hard exit is often expected.
    }
} else {
    Write-Host "[PASS] Todos los chequeos pasaron exitosamente." -ForegroundColor Green
    Write-Host "`nGATE RESULT: PASS" -ForegroundColor Green
}