#requires -Version 5.1
<#
.SYNOPSIS
    Auditoria estructural de solo lectura para CHECK_ADOR_AISTUDIO.
.DESCRIPTION
    Distingue inventario, evidencia estatica y ejecucion real.
    No instala dependencias, no compila, no ejecuta pruebas y no modifica archivos.
    Las puntuaciones son orientativas: NO certifican comportamiento en produccion.
.EXAMPLE
    .\audit-salud-checador.ps1 -TargetDir 'Y:\Documentos\GitHub\CHECK_ADOR_AISTUDIO'
.EXAMPLE
    .\audit-salud-checador.ps1 -TargetDir . -IncludeBackups
#>
[CmdletBinding()]
param(
    [string]$TargetDir = (Get-Location).Path,
    [switch]$IncludeBackups
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section([string]$Title) {
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
}
function Test-File([string]$RelativePath) {
    Test-Path -LiteralPath (Join-Path $root $RelativePath) -PathType Leaf
}
function Test-Dir([string]$RelativePath) {
    Test-Path -LiteralPath (Join-Path $root $RelativePath) -PathType Container
}
function Get-CommandStatus([string]$Name) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) { 'DISPONIBLE' } else { 'NO_DISPONIBLE' }
}
function Get-SourceInventory([string]$Module) {
    $base = Join-Path $root $Module
    $files = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
function Read-Source([System.IO.FileInfo]$File) {
    try { return [System.IO.File]::ReadAllText($File.FullName) }
    catch { Write-Warning "No se pudo leer $($File.FullName)"; return '' }
}
function Inspect-Module([string]$Module) {
    $allModuleFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($base)
    $stack.Push((Join-Path $root $Module))
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        try { $items = @(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop) }
        catch { Write-Warning "Sin acceso a ${current}: $($_.Exception.Message)"; continue }
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                if ($excludedDirs -contains $item.Name.ToLowerInvariant()) { continue }
                if (-not $IncludeBackups -and $item.Name -eq 'Restaurar INTERFAZ') { continue }
                if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                $stack.Push($item.FullName)
            } elseif ($sourceExtensions -contains $item.Extension.ToLowerInvariant()) {
                $files.Add($item)
            }
            else {
                $allModuleFiles.Add($item)
            }
        }
    }
    # Emitir FileInfo individualmente; evitar un arreglo anidado que rompa Read-Source.
    foreach ($foundFile in $files) { Write-Output $foundFile }
}
function Read-Source([System.IO.FileInfo]$File) {
    try { return [System.IO.File]::ReadAllText($File.FullName) }
    catch { Write-Warning "No se pudo leer $($File.FullName)"; return '' }
}
function Inspect-Module([string]$Module) {
    $files = @(Get-SourceInventory $Module)
    $files = @($allModuleFiles | Where-Object { $sourceExtensions -contains $_.Extension.ToLowerInvariant() })
    $testFiles = @($files | Where-Object { $_.Name -match '(^test[_\.-]|[_\.-]test\.|\.spec\.|Tests?\.)' })
    $empty = @($files | Where-Object { $_.Length -eq 0 })
    $empty = @($allModuleFiles | Where-Object { $_.Length -eq 0 })
    $todo = 0; $fixme = 0; $placeholders = 0; $lines = 0
    $examples = New-Object 'System.Collections.Generic.List[string]'
    foreach ($file in $files) {
        $content = Read-Source $file
        if ($content.Length -eq 0) { continue }
        $lines += [regex]::Matches($content, '\r\n|\n|\r').Count + 1
        $todo += [regex]::Matches($content, '(?im)\bTODO\b').Count
        $fixme += [regex]::Matches($content, '(?im)\bFIXME\b').Count
        $found = [regex]::Matches($content, '(?im)NotImplementedError|\bNotImplementedException\b|throw\s+new\s+Error\s*\(\s*["\x27]Not implemented')
        $found = [regex]::Matches($content, '(?im)\bPLACEHOLDER\b|\bNOT\s+IMPLEMENTED\b|\bIMPLEMENT\s+ME\b|NotImplementedError|\bNotImplementedException\b|throw\s+new\s+Error\s*\(\s*["\x27]Not implemented')
        $placeholders += $found.Count
        if ($found.Count -gt 0 -and $examples.Count -lt 8) {
            $relative = $file.FullName.Substring($root.Length).TrimStart('\','/')
            $examples.Add("$relative ($($found.Count))")
        }
    }
    # Indice orientativo de higiene: no es una prueba de funcionalidad.
    $score = [math]::Max(0, 100 - [math]::Min(20, $empty.Count * 3) - [math]::Min(15, $todo * 2) - [math]::Min(15, $fixme * 3) - [math]::Min(20, $placeholders * 4) - $(if ($files.Count -gt 0 -and $testFiles.Count -eq 0) { 10 } else { 0 }))
    $score = 100
    $score -= [math]::Min(20, $empty.Count * 3)
    $score -= [math]::Min(15, $todo * 2)
    $score -= [math]::Min(15, $fixme * 3)
    $score -= [math]::Min(20, $placeholders * 4)
    if ($files.Count -gt 0) {
        if ($testFiles.Count -eq 0) {
            $score -= 15
        } else {
            $ratio = $testFiles.Count / $files.Count
            if ($ratio -lt 0.05) { $score -= 10 }
            elseif ($ratio -lt 0.1) { $score -= 5 }
        }
    }
    [pscustomobject]@{
        Module = $Module; Score = [int]$score; CodeFiles = $files.Count
        TestFiles = $testFiles.Count; Lines = $lines; Empty = $empty.Count
        TODO = $todo; FIXME = $fixme; Placeholders = $placeholders
        Examples = @($examples.ToArray())
    }
}
function Inspect-Wiring([string]$RelativePath, [string]$Pattern, [string]$Label) {
    if (-not (Test-File $RelativePath)) {
        Write-Host "[NO_VERIFICABLE] $Label - archivo ausente: $RelativePath" -ForegroundColor Yellow
        return
    }
    $body = [System.IO.File]::ReadAllText((Join-Path $root $RelativePath))
    if ([regex]::IsMatch($body, $Pattern)) {
        Write-Host "[EVIDENCIA_ESTATICA] $Label - coincidencia en $RelativePath" -ForegroundColor Cyan
    } else {
        Write-Host "[NO_DETECTADO] $Label - sin coincidencia en $RelativePath" -ForegroundColor Yellow
    }
}

try { $root = (Resolve-Path -LiteralPath $TargetDir -ErrorAction Stop).ProviderPath }
catch { throw "Directorio no accesible: $TargetDir" }
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "No es directorio: $root" }

$excludedDirs = @('.git', 'node_modules', 'dist', 'build', 'coverage', '.next', '.venv', 'venv', '__pycache__', '.pytest_cache', '.mypy_cache', '.turbo', '.cache', 'target', 'bin', 'obj')
$sourceExtensions = @('.py', '.ps1', '.psm1', '.ts', '.tsx', '.js', '.jsx', '.go', '.rs', '.cs')
$modules = @('src', 'frontend', 'backend', 'checker', 'scripts')
if ($IncludeBackups -and (Test-Dir 'Restaurar INTERFAZ')) { $modules += 'Restaurar INTERFAZ' }

Write-Section 'CHECADOR_KLIK - AUDITORIA DE SALUD (SOLO LECTURA)'
Write-Host "Proyecto: $root"
Write-Host 'Alcance: estructura, inventario, indicadores de conexion y entorno'
Write-Host 'Pruebas dinamicas ejecutadas: 0 (NO_EJECUTADAS)'

Write-Section '1/4 - STACK Y ENTORNO'
$frontend = Test-File 'frontend/package.json'
$rootNode = Test-File 'package.json'
$python = (Test-Dir 'checker') -or (Test-File 'pyproject.toml') -or (Test-File 'api.py')
Write-Host "Frontend Node/React: $(if ($frontend -or $rootNode) {'DETECTADO'} else {'NO_DETECTADO'})"
Write-Host "Backend Python: $(if ($python) {'DETECTADO'} else {'NO_DETECTADO'})"
foreach ($cmd in @('git', 'node', 'npm', 'python', 'pytest', 'pwsh')) {
    Write-Host ("  {0,-12} {1}" -f $cmd, (Get-CommandStatus $cmd))
}
Write-Host 'NOTA: herramientas disponibles != compilacion o pruebas aprobadas.' -ForegroundColor DarkYellow

Write-Section '2/4 - INVENTARIO POR MODULO'
$results = @()
foreach ($module in $modules) {
    if (Test-Dir $module) {
        Write-Host "Inspeccionando $module ..." -ForegroundColor DarkGray
        $results += Inspect-Module $module
    } else {
        Write-Host "[NO_DETECTADO] $module" -ForegroundColor Yellow
    }
}
if ($results.Count -gt 0) {
    $results | Select-Object Module, Score, CodeFiles, TestFiles, Lines, Empty, TODO, FIXME, Placeholders | Format-Table -AutoSize
    $average = [math]::Round((($results | Measure-Object -Property Score -Average).Average), 2)
    Write-Host "Indice estructural orientativo: $average / 100" -ForegroundColor Yellow
    foreach ($result in $results) {
        if ($result.Examples.Count -gt 0) {
            Write-Host "  Posibles implementaciones pendientes en $($result.Module): $($result.Examples -join '; ')" -ForegroundColor Yellow
        }
    }
}
if (-not $IncludeBackups -and (Test-Dir 'Restaurar INTERFAZ')) {
    Write-Host '[EXCLUIDO] Restaurar INTERFAZ (respaldo; no suma ni resta puntuacion)' -ForegroundColor DarkYellow
}

Write-Section '3/4 - CONEXIONES CRITICAS'
Inspect-Wiring 'frontend/src/modules/code-auditor/CodeAuditorView.tsx' 'webkitdirectory|showDirectoryPicker' 'Selector de carpetas en auditor principal'
Inspect-Wiring 'src/services/FolderImportModal.tsx' 'showDirectoryPicker' 'Selector inteligente disponible'
Inspect-Wiring 'src/services/directoryScanner.ts' 'scanDirectoryHandle|scanFileList' 'Motor de poda y filtrado'
Inspect-Wiring 'frontend/src/modules/testing/TestSuiteRunnerView.tsx' 'executeFullSuite' 'Controlador de bateria de pruebas'
Inspect-Wiring 'frontend/src/modules/testing/TestSuiteRunnerView.tsx' 'runSingleTest' 'Despacho individual de pruebas'
Inspect-Wiring 'src/services/testRunner.ts' 'case\s+["\x27]stress["\x27]' 'Implementacion de la regla STRESS (no demuestra ejecucion real)'
Inspect-Wiring 'frontend/src/modules/projects/ProjectTree.tsx' 'ProjectTree' 'Componente TREE'
Inspect-Wiring 'backend/api/powershell.py' 'powershell' 'Endpoint PowerShell'

Write-Section '4/4 - DICTAMEN'
Write-Host '[NO_EJECUTADO] Build del frontend, pytest, Pester, carga, estres, failover, LIVE y 55 pruebas.' -ForegroundColor Yellow
Write-Host '[NO_VERIFICADO] Integracion funcional, mediciones P95/P99, despliegue y botones.' -ForegroundColor Yellow
Write-Host 'La presencia de archivos o texto no equivale a un PASS funcional.' -ForegroundColor Yellow
Write-Host 'No se modifico ningun archivo del proyecto.' -ForegroundColor Green
