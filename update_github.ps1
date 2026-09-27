[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Message = "",
    [string]$Branch = ""
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Generar-MensajeCommit {
    param([string[]]$ArchivosModificados)

    if (-not $ArchivosModificados -or $ArchivosModificados.Count -eq 0) {
        return "chore: sync repository updates"
    }

    $paths = $ArchivosModificados | ForEach-Object { $_ -replace "^[A-Z\?]\s+", "" }
    $docsOnly = ($paths | Where-Object { $_ -notmatch '(?i)(\.md$|^docs/)' }).Count -eq 0
    $testsOnly = ($paths | Where-Object { $_ -notmatch '(?i)(tests/|test|\.spec\.)' }).Count -eq 0
    $scriptsOnly = ($paths | Where-Object { $_ -notmatch '(?i)\.(ps1|cmd|bat|sh)$' }).Count -eq 0

    $tipo = "chore"
    $scope = ""
    $descripcion = ""

    if ($docsOnly) {
        $tipo = "docs"
        $descripcion = "update documentation and integrity baselines"
    }
    elseif ($testsOnly) {
        $tipo = "test"
        $descripcion = "update test suites and regression specs"
    }
    elseif ($scriptsOnly) {
        $tipo = "chore"
        $scope = "(scripts)"
        $descripcion = "update build and audit automation scripts"
    }
    elseif ($paths | Where-Object { $_ -match '(?i)Presentation\.Api' }) {
        $tipo = "feat"
        $scope = "(api)"
        $descripcion = "update api endpoints and middleware pipeline"
    }
    elseif ($paths | Where-Object { $_ -match '(?i)Presentation\.Desktop' }) {
        $tipo = "feat"
        $scope = "(desktop)"
        $descripcion = "update MAUI desktop views and components"
    }
    elseif ($paths | Where-Object { $_ -match '(?i)Presentation\.Web' }) {
        $tipo = "feat"
        $scope = "(web)"
        $descripcion = "update react web panel components"
    }
    elseif ($paths | Where-Object { $_ -match '(?i)Infrastructure|Application|Domain' }) {
        $tipo = "refactor"
        $scope = "(core)"
        $descripcion = "update domain logic and infrastructure services"
    }
    else {
        $tipo = "chore"
        $descripcion = "sync repository changes across $($paths.Count) file(s)"
    }

    return "$tipo${scope}: $descripcion ($((Get-Date).ToString('yyyy-MM-dd HH:mm')))"
}

if ([string]::IsNullOrWhiteSpace($Branch)) {
    $Branch = (git branch --show-current 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($Branch)) { $Branch = "main" }
}

Write-Host ">>> Analizando y agregando cambios en rama '$Branch'..." -ForegroundColor Cyan
& git add -A

$staged = @(& git diff --cached --name-status 2>$null)
if (-not $staged -or $staged.Count -eq 0) {
    Write-Host "[OK] No hay cambios pendientes para confirmar ni subir." -ForegroundColor Yellow
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = Generar-MensajeCommit -ArchivosModificados $staged
    Write-Host "[AUTO-COMMIT] Mensaje generado: $Message" -ForegroundColor Yellow
}

& git commit -m "$Message"
& git push origin $Branch
Write-Host ">>> Sincronizacion completada con exito." -ForegroundColor Green