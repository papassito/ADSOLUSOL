# CHISMOSA_BUILD_DIAGNOSTIC.ps1
# Extrae la lista exacta de archivos, líneas y errores que hacen fallar dotnet build

$dotnetPath = "C:\Users\Radio 2027\Documents\Codex\tools\dotnet\dotnet.exe"
if (-not (Test-Path $dotnetPath)) {
    $dotnetPath = (Get-Command dotnet -ErrorAction SilentlyContinue).Source
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " DIAGNÓSTICO DE ERRORES DE COMPILACIÓN (SACANDO LA SOPA)" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$tempLog = Join-Path $PSScriptRoot "_build_error_raw.log"

# Ejecutar build capturando la salida cruda
& $dotnetPath build ADSOLUSOL.sln /v:q /noconlog > $tempLog 2>&1

$logContent = Get-Content $tempLog -Encoding UTF8

# Regex para detectar errores de C# (archivo.cs(línea,col): error CSxxxx: mensaje)
$errorRegex = '^(?<file>.*?\.cs)\((?<line>\d+),(?<col>\d+)\):\s+error\s+(?<code>CS\d+):\s+(?<msg>.*)$'

$errors = @()
foreach ($line in $logContent) {
    if ($line -match $errorRegex) {
        $errors += [PSCustomObject]@{
            Archivo = $Matches['file']
            Linea   = $Matches['line']
            Codigo  = $Matches['code']
            Mensaje = $Matches['msg'].Trim()
        }
    }
}

Remove-Item $tempLog -Force -ErrorAction SilentlyContinue

if ($errors.Count -eq 0) {
    Write-Host "`n[!] No se detectaron errores de código C#. El fallo de build se debe a un problema de MSBuild, archivo corrupto o proceso bloqueado." -ForegroundColor Yellow
    Write-Host "`nSalida cruda del compilador:" -ForegroundColor Gray
    $logContent | Select-Object -Last 20 | ForEach-Host { Write-Host $_ -ForegroundColor Red }
} else {
    Write-Host "`n[CRÍTICO] Se encontraron $($errors.Count) error(es) de compilación:`n" -ForegroundColor Red
    
    $grouped = $errors | Group-Object Archivo
    foreach ($group in $grouped) {
        Write-Host "📄 ARCHIVO: $($group.Name)" -ForegroundColor Yellow
        foreach ($err in $group.Group) {
            Write-Host "   ├── Línea $($err.Linea): [$($err.Codigo)] $($err.Mensaje)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan