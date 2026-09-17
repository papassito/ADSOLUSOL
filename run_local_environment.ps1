# ==============================================================================
# ADSOLUSOL & SOLUSOL_SIC — BACKGROUND JOBS LAUNCHER (SIN CIERRES REPENTINOS)
# ==============================================================================
Param(
    [switch]$Stop
)

# Si el usuario ejecuta .\run_local_environment.ps1 -Stop, se detienen los procesos
if ($Stop) {
    Write-Host "[INFO] Deteniendo servicios en segundo plano..." -ForegroundColor Yellow
    Get-Job | Stop-Job
    Get-Job | Remove-Job
    Write-Host "[OK] Todos los servicios se han detenido." -ForegroundColor Green
    exit 0
}

# 1. Configurar PATH de la sesión activa
$env:PATH += ";C:\Program Files\dotnet"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " INICIANDO SERVICIOS EN SEGUNDO PLANO (BACKGROUND JOBS)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# RUTA DEL MOTOR GO
$goDirPath = "Y:\Documentos\GitHub\SOLUSOL_SIC"

# 2. Compilar Motor Go
Write-Host "[1/2] Compilando motor Go..." -ForegroundColor Yellow
Push-Location $goDirPath
try {
    go build -o solusol_sic.exe .
    Write-Host "[PASS] Binario Go listo." -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error al compilar Go: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# 3. Compilar API .NET
Write-Host "[2/2] Compilando API .NET 8..." -ForegroundColor Yellow
try {
    dotnet build "Y:\Documentos\GitHub\ADSOLUSOL\ADSOLUSOL.sln" -c Release
    Write-Host "[PASS] Solución .NET lista." -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Error al compilar .NET: $_" -ForegroundColor Red
    exit 1
}

# 4. Iniciar Trabajos en Segundo Plano
Write-Host "`n>>> Iniciando Motor Go en Job (puerto 8080)..." -ForegroundColor Cyan
Start-Job -Name "GoEngine" -ScriptBlock {
    Set-Location "Y:\Documentos\GitHub\SOLUSOL_SIC"
    .\solusol_sic.exe
}

Write-Host ">>> Iniciando API .NET 8 en Job (puerto 5000)..." -ForegroundColor Cyan
Start-Job -Name "DotNetApi" -ScriptBlock {
    $env:PATH += ";C:\Program Files\dotnet"
    Set-Location "Y:\Documentos\GitHub\ADSOLUSOL\src\ADSOLUSOL.Presentation.Api"
    dotnet run -c Release
}

Start-Sleep -Seconds 3

# Mostrar estado de los trabajos
Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host " ESTADO DE LOS SERVICIOS" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Get-Job

Write-Host "`n💡 Instrucciones de control:" -ForegroundColor White
Write-Host " - Ver logs de Go:   Receive-Job -Name GoEngine -Keep" -ForegroundColor Gray
Write-Host " - Ver logs de .NET: Receive-Job -Name DotNetApi -Keep" -ForegroundColor Gray
Write-Host " - Detener todo:     .\run_local_environment.ps1 -Stop" -ForegroundColor Gray