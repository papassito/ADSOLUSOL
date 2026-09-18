[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }

$auditFailed = $false
$failureMessages = [System.Collections.Generic.List[string]]::new()

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " ADSOLUSOL — AUDITORÍA Y CERTIFICACIÓN ULTRA SUPERCHISMOSA (v2.0)" -ForegroundColor Cyan
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
    $failureMessages.Add("[CRITICAL] No se encontró el archivo 'ADSOLUSOL.sln' en la raíz.")
    $auditFailed = $true
} else {
    Write-Host "[OK] Solucion bajo analisis: $slnPath`n" -ForegroundColor Green
}

if (-not $auditFailed) {
    Write-Host ">>> [FASE 1] Compilando la solucion..." -ForegroundColor Yellow
    $buildOut = & $dotnetExe build $slnPath --nologo 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        $auditFailed = $true
        $failureMessages.Add("[FAIL] Errores de compilación detectados.")
        $errorRegex = '^(?<file>.*?\.cs)\((?<line>\d+),(?<col>\d+)\):\s+error\s+(?<code>CS\d+):\s+(?<msg>.*)$'
        $csErrors = @($buildOut | Where-Object { $_ -match $errorRegex } | ForEach-Object {
            [PSCustomObject]@{
                Archivo = $Matches['file']
                Linea   = $Matches['line']
                Codigo  = $Matches['code']
                Mensaje = $Matches['msg'].Trim()
            }
        })

        if ($csErrors.Count -gt 0) {
            $grouped = $csErrors | Group-Object Archivo
            foreach ($group in $grouped) {
                $failureMessages.Add("`nARCHIVO: $($group.Name)")
                foreach ($err in $group.Group) {
                    $failureMessages.Add("   -> Linea $($err.Linea): [$($err.Codigo)] $($err.Mensaje)")
                }
            }
        } else {
            $failureMessages.Add("`n[!] Salida cruda del compilador:")
            foreach ($line in $buildOut) {
                $failureMessages.Add($line.ToString())
            }
        }
    } else {
        Write-Host "[PASS] Compilación exitosa (0 Errores)." -ForegroundColor Green
    }
}

if (-not $auditFailed) {
    Write-Host "`n>>> [FASE 2] Ejecutando proyectos de prueba..." -ForegroundColor Yellow
    $testProjects = @(Get-ChildItem -Path $Root -Filter "*Test*.csproj" -Recurse)

    if ($testProjects.Count -eq 0) {
        Write-Host "[INFO] No se localizaron proyectos de prueba estándar. Omitiendo." -ForegroundColor Gray
    } else {
        foreach ($testProj in $testProjects) {
            Write-Host "`nEjecutando Suite: $($testProj.Name)" -ForegroundColor Cyan
            
            $isExecutable = (Get-Content $testProj.FullName) -join "`n" | Select-String -Pattern "<OutputType>Exe</OutputType>" -Quiet
            # Forma más eficiente y robusta de detectar si un proyecto es un ejecutable.
            $isExecutable = Select-String -Path $testProj.FullName -Pattern "<OutputType>Exe</OutputType>" -Quiet
            if ($isExecutable) {
                Write-Host "   [INFO] Proyecto ejecutable detectado. Usando 'dotnet run'." -ForegroundColor Gray
                $testOut = & $dotnetExe run --project "$($testProj.FullName)" --no-build 2>&1
            } else {
                $testOut = & $dotnetExe test "$($testProj.FullName)" --no-build --nologo -v:q 2>&1
                # Usar -v:normal para capturar más detalles en caso de error, como en SOPA-COMPLETA.
                $testOut = & $dotnetExe test "$($testProj.FullName)" --no-build --nologo -v:normal 2>&1
            }

            if ($LASTEXITCODE -ne 0) {
                $auditFailed = $true
                $failureMessages.Add("[FAIL] Fallaron pruebas en: $($testProj.Name)")
                # Capturar y registrar los detalles del error, no solo el hecho de que falló.
                $testErrors = $testOut | Where-Object { $_ -match "Failed|Error|Exception|Stack Trace" }
                foreach ($errLine in $testErrors) {
                    $failureMessages.Add("      -> $($errLine.ToString().Trim())")
                }
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
    foreach ($msg in $failureMessages) {
        Write-Host $msg -ForegroundColor Red
    }
    Write-Host "`nGATE RESULT: FAIL" -ForegroundColor Red
} else {
    Write-Host "[PASS] Todos los chequeos pasaron exitosamente." -ForegroundColor Green
    Write-Host "`nGATE RESULT: PASS" -ForegroundColor Green
}