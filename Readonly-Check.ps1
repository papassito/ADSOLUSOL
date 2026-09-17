$ErrorActionPreference = "Continue"
$RootPath = "Y:\Documentos\GitHub\ADSOLUSOL"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   DIAGNÓSTICO DE SOLO LECTURA - ADSOLUSOL        " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/2] Verificando referencias PackageReference en Infrastructure:" -ForegroundColor Yellow
$infraCsproj = Join-Path $RootPath "src\ADSOLUSOL.Infrastructure\ADSOLUSOL.Infrastructure.csproj"
if (Test-Path $infraCsproj) {
    Select-String -Path $infraCsproj -Pattern "<PackageReference" | ForEach-Object {
        Write-Host "  -> $($_.Line.Trim())" -ForegroundColor Cyan
    }
}

Write-Host "`n[2/2] Ejecutando compilación sin incrementalidad..." -ForegroundColor Yellow
Set-Location $RootPath
$buildLogs = dotnet build --no-incremental --configuration Release 2>&1

$errors = $buildLogs | Where-Object { $_ -match "error CS" }

if ($errors) {
    Write-Host "`n--- RESUMEN EXACTO DE ERRORES ENCONTRADOS ($($errors.Count)) ---" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host " $err" -ForegroundColor Red
    }
} else {
    Write-Host "`n  [ÉXITO] La solución compila correctamente sin errores." -ForegroundColor Green
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "             DIAGNÓSTICO FINALIZADO               " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
