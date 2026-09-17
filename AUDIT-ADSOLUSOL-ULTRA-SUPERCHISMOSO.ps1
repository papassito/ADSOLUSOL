$ErrorActionPreference = "Continue"
$Root = $PSScriptRoot
if (-not $Root) { $Root = (Get-Location).Path }

$auditFailed = $false
$failureMessages = [System.Collections.Generic.List[string]]::new()

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL - AUDITORIA Y CERTIFICACION ULTRA SUPERCHISMOSA (v2.1)" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

$dotnetExe = (Get-Command "dotnet" -ErrorAction SilentlyContinue).Source
if (-not $dotnetExe) {
    $failureMessages.Add("[CRITICAL] dotnet no encontrado en PATH.")
    $auditFailed = $true
} else {
    Write-Host "[OK] Ejecutable .NET detectado: $dotnetExe" -ForegroundColor Green
}

$slnPath = Join-Path $Root "ADSOLUSOL.sln"
if (-not (Test-Path $slnPath)) {
    $failureMessages.Add("[CRITICAL] No se encontro el archivo 'ADSOLUSOL.sln' en la raiz.")
    $auditFailed = $true
} else {
    Write-Host "[OK] Solucion bajo analisis: $slnPath`n" -ForegroundColor Green
}

if (-not $auditFailed) {
    Write-Host ">>> [FASE 1] Compilando la solucion..." -ForegroundColor Yellow
    $buildOut = & $dotnetExe build$slnPath --nologo 2>&1
    
    if ($LASTEXITCODE -ne 0) {$auditFailed = $true$failureMessages.Add("[FAIL] Errores de compilacion detectados.")
        $errorRegex = '^(?<file>.*?\.cs)\((?<line>\d+),(?<col>\d+)\):\s+error\s+(?<code>CS\d+):\s+(?<msg>.*)$'
        $csErrors = @($buildOut | Where-Object { $_ -match$errorRegex } | ForEach-Object {
            [PSCustomObject]@{
                Archivo = $Matches['file']
                Linea   = $Matches['line']
                Codigo  = $Matches['code']
                Mensaje = $Matches['msg'].Trim()
            }
        })

        if ($csErrors.Count -gt 0) {
            $grouped =$csErrors | Group-Object Archivo
            foreach ($group in $grouped) {$failureMessages.Add("`nARCHIVO: $($group.Name)")
                foreach ($err in $group.Group) {
                    $failureMessages.Add("   -> Linea $($err.Linea): [$($err.Codigo)] $($err.Mensaje)")
                }
            }
        } else {
            $failureMessages.Add("`n[!] Salida cruda del compilador:")
            foreach ($line in$buildOut) {
                $failureMessages.Add($line.ToString())
            }
        }
    } else {
        Write-Host "[PASS] Compilacion exitosa (0 Errores)." -ForegroundColor Green
    }
}

if (-not $auditFailed) {
    Write-Host "`n>>> [FASE 2] Ejecutando proyectos de prueba..." -ForegroundColor Yellow
    $testProjects = @(Get-ChildItem -Path $Root -Filter "*Test*.csproj" -Recurse)

    if ($testProjects.Count -eq 0) {
        Write-Host "[INFO] No se localizaron proyectos de prueba. Omitiendo." -ForegroundColor Gray
    } else {
        foreach ($testProj in $testProjects) {
            $projContent = Get-Content -Path $testProj.FullName -Raw
            $isExe = $projContent -match "<OutputType>\s*Exe\s*</OutputType>"

            if ($isExe) {
                Write-Host "`nEjecutando Suite Ejecutable (dotnet run): $($testProj.Name)" -ForegroundColor Cyan
                $testOut = &$dotnetExe run --project "$($testProj.FullName)" --no-build --nologo 2>&1
            } else {
                Write-Host "`nEjecutando Suite de Pruebas (dotnet test): $($testProj.Name)" -ForegroundColor Cyan
                $testOut = & $dotnetExe test "$($testProj.FullName)" --no-build --nologo -v:q 2>&1
            }

            if ($LASTEXITCODE -ne 0) {
                $auditFailed = $true
                $failureMessages.Add("[FAIL] Fallaron pruebas en: $($testProj.Name)")
            } else {
                Write-Host "   [OK] Pruebas pasaron." -ForegroundColor Green
            }
        }
    }
}

Write-Host "`n==============================================================================" -ForegroundColor Cyan
Write-Host " RESULTADO DE LA AUDITORIA" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

if ($auditFailed) {
    Write-Host "[FAIL] Resumen de problemas:" -ForegroundColor Red
    foreach ($msg in$failureMessages) {
        Write-Host $msg -ForegroundColor Red
    }
    Write-Host "`nGATE RESULT: FAIL" -ForegroundColor Red
} else {
    Write-Host "[PASS] Todos los chequeos pasaron exitosamente." -ForegroundColor Green
    Write-Host "`nGATE RESULT: PASS" -ForegroundColor Green
}