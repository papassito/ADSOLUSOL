Clear-Host
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " 🕵️‍♂️ EL CHISMOSO FORENSE :: AUDITOR DE SUITES Y CALIDAD (.NET 8)" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

Get-Process -Name "*testhost*", "*adsolusol*" -ErrorAction SilentlyContinue | Stop-Process -Force

$rootChismoso = Join-Path $RepoRoot "chismoso.ps1"
if (Test-Path $rootChismoso) {
    & $rootChismoso @args
    exit $LASTEXITCODE
}

Push-Location $RepoRoot
try {
    & dotnet test ADSOLUSOL.sln -c Release --nologo -v:minimal
} finally {
    Pop-Location
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n🟢 VERDICTO: SUITE DE PRUEBAS COMPLETA EN PASS." -ForegroundColor Green
} else {
    Write-Host "`n🔴 VERDICTO: AÚN QUEDAN DETALLES EN LAS PRUEBAS." -ForegroundColor Red
}
