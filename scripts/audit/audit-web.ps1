<#[
  ADSOLUSOL :: AUDITOR DE PRESENTACION WEB (NASA GRADE)
  Inspeccion estricta: Arquitectura React/Vite, SRP modular (<250 lineas en App.tsx),
  ausencia de BOM/Mojibake, veto a console.log/debugger, y cobertura de sitemap.
]#>
[CmdletBinding()]
param([string]$Root = $PSScriptRoot)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$base = (Resolve-Path $Root).Path
while ($base -and -not (Test-Path (Join-Path $base 'ADSOLUSOL.sln'))) {
    $parent = Split-Path $base -Parent
    if ($parent -eq $base) { break }
    $base = $parent
}
$module = Join-Path $base 'src\ADSOLUSOL.Presentation.Web'
$fails = 0; $warns = 0
function Pass($code,$msg) { Write-Host "  [PASS] [$code] $msg" -ForegroundColor Green }
function Fail($code,$msg) { Write-Host "  [FAIL] [$code] $msg" -ForegroundColor Red; $script:fails++ }
function Warn($code,$msg) { Write-Host "  [WARN] [$code] $msg" -ForegroundColor Yellow; $script:warns++ }

Write-Host '===========================================================================' -ForegroundColor Cyan
Write-Host ' [WEB] AUDITORIA DE PRESENTACION WEB (NASA GRADE)' -ForegroundColor Cyan
Write-Host "Directorio Base: $base`n" -ForegroundColor DarkGray
if (-not (Test-Path $module)) { Fail 'WEB-PATH' 'No se localizo src\ADSOLUSOL.Presentation.Web.'; exit 1 }

# 1. Estructura base de empaquetado y configuracion
$package = Join-Path $module 'package.json'
$viteConfig = Join-Path $module 'vite.config.ts'
$src = Join-Path $module 'src'
if (Test-Path $package) { Pass 'WEB-PACKAGE' 'package.json esta presente.' } else { Fail 'WEB-PACKAGE' 'Falta package.json.' }
if (Test-Path $viteConfig) { Pass 'WEB-CONFIG' 'vite.config.ts esta presente.' } else { Fail 'WEB-CONFIG' 'Falta vite.config.ts.' }
if (Test-Path $src) { Pass 'WEB-SRC' 'Directorio src esta presente.' } else { Fail 'WEB-SRC' 'Falta el directorio src.' }

# 2. Inventario e higiene forense de archivos
$code = @(Get-ChildItem $src -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Extension -in '.ts','.tsx','.js','.jsx','.css' -and
        $_.FullName -notmatch '\\(node_modules|dist|build|coverage|bin|obj)\\'
    })
if ($code.Count -eq 0) { Fail 'WEB-CODE' 'No se detectaron archivos de frontend.' } else { Pass 'WEB-CODE' "Se inspeccionaron $($code.Count) archivos de frontend." }

# 3. Inspeccion de BOM UTF-8, Mojibake y caracteres nulos
$encodingIssues = 0
foreach ($f in $code) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Fail 'WEB-BOM' "$($f.Name) contiene UTF-8 BOM prohibido."
        $encodingIssues++
    }
    $rawText = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($rawText -match "(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})") {
        Fail 'WEB-MOJIBAKE' "$($f.Name) contiene secuencias corruptas de Mojibake."
        $encodingIssues++
    }
    if ($rawText.Contains([char]0xFFFD)) {
        Fail 'WEB-UNICODE' "$($f.Name) contiene caracter corrupto \uFFFD."
        $encodingIssues++
    }
}
if ($encodingIssues -eq 0) { Pass 'WEB-ENCODING' 'Higiene de codificacion 100% limpia (UTF-8 sin BOM, cero mojibake).' }

# 4. Verificacion estricta de Single Responsibility Principle (SRP)
$app = Join-Path $src 'App.tsx'
if (Test-Path $app) {
    $appLines = (Get-Content $app).Count
    if ($appLines -gt 250) { 
        Fail 'WEB-SRP-APP' "App.tsx excede el umbral estricto NASA de 250 lineas ($appLines lineas registradas)." 
    } else { 
        Pass 'WEB-SRP-APP' "App.tsx cumple con SRP modular ($appLines lineas <= 250)." 
    }
} else { Fail 'WEB-ENTRY' 'No se encontro App.tsx como raiz de presentacion.' }

# Umbral maximo para vistas y componentes individuales (350 lineas)
$oversized = @()
foreach ($f in $code) {
    if ($f.Name -ne 'App.tsx') {
        $lCount = (Get-Content $f.FullName).Count
        if ($lCount -gt 350) { $oversized += "$($f.Name) ($lCount lineas)" }
    }
}
if ($oversized.Count -eq 0) {
    Pass 'WEB-SRP-COMPONENTS' 'Todos los componentes y vistas individuales estan debajo de 350 lineas.'
} else {
    Warn 'WEB-SRP-COMPONENTS' "Componentes sobredimensionados: $($oversized -join ', ')."
}

# 5. Inspeccion de deuda tecnica, depuradores y secretos
$debugDebt = 0
foreach ($f in $code) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($content -match '\bdebugger\b') {
        Fail 'WEB-DEBUGGER' "Instruccion 'debugger' encontrada en $($f.Name)."
        $debugDebt++
    }
    if ($content -match '\bconsole\.log\s*\(') {
        Warn 'WEB-CONSOLE' "Llamada a console.log detectada en $($f.Name)."
    }
    if ($content -match '\bTODO\b|\bFIXME\b|NotImplementedException') {
        Fail 'WEB-DEBT' "Marcador de deuda tecnica o stub incompleto en $($f.Name)."
        $debugDebt++
    }
}
if ($debugDebt -eq 0) { Pass 'WEB-HYGIENE' 'Cero stubs incompletos, cero TODO/FIXME y cero sentencias debugger.' }

# 6. Cobertura obligatoria de vistas segun Sitemap
$requiredViews = @('DashboardView.tsx', 'CampaignsView.tsx', 'PlacementsView.tsx', 'CreativesView.tsx', 'AssignmentsView.tsx', 'ServeView.tsx', 'SystemView.tsx', 'SettingsView.tsx', 'LoginView.tsx')
$missingViews = @()
foreach ($rv in $requiredViews) {
    $found = $code | Where-Object { $_.Name -eq $rv }
    if (-not $found) { $missingViews += $rv }
}
if ($missingViews.Count -eq 0) {
    Pass 'WEB-SITEMAP-COVERAGE' "Todas las 9 vistas canónicas del frontend estan implementadas y segregadas."
} else {
    Fail 'WEB-SITEMAP-COVERAGE' "Vistas faltantes segun sitemap: $($missingViews -join ', ')."
}

# 7. Estructura fisica de directorios modulares
$componentsDir = Join-Path $src 'components'
$viewsDir = Join-Path $src 'views'
if (Test-Path $componentsDir) { Pass 'WEB-DIR-COMPONENTS' 'Directorio src/components presente.' } else { Fail 'WEB-DIR-COMPONENTS' 'Falta el directorio src/components.' }
if (Test-Path $viewsDir) { Pass 'WEB-DIR-VIEWS' 'Directorio src/views presente.' } else { Fail 'WEB-DIR-VIEWS' 'Falta el directorio src/views.' }

# 8. Resolucion estricta de imports relativos (Cero imports rotos)
$brokenImports = 0
$importRegex = [regex]'(?:from\s+|import\s+)["''](\.[^"'']+)["'']'
foreach ($f in $code) {
    if ($f.Extension -notin @('.ts', '.tsx', '.js', '.jsx')) { continue }
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $matches = $importRegex.Matches($content)
    foreach ($m in $matches) {
        $relImport = $m.Groups[1].Value
        $dir = $f.DirectoryName
        $candidateBase = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($dir, $relImport))
        $candidateExtensions = @('', '.ts', '.tsx', '.d.ts', '.js', '.jsx', '.css', '/index.ts', '/index.tsx', '/index.js', '/index.jsx')
        $resolved = $false
        foreach ($ext in $candidateExtensions) {
            $target = $candidateBase + $ext
            if ([System.IO.File]::Exists($target)) {
                $resolved = $true
                break
            }
        }
        if (-not $resolved) {
            Fail 'WEB-BROKEN-IMPORT' "$($f.Name): import no resuelto '$relImport'."
            $brokenImports++
        }
    }
}
if ($brokenImports -eq 0) {
    Pass 'WEB-IMPORTS' 'Todos los imports relativos resuelven a archivos existentes en disco.'
}

# 7. Archivos de 0 bytes
$empty = @($code | Where-Object Length -eq 0)
if ($empty.Count -eq 0) { Pass 'WEB-EMPTY' 'No hay archivos de frontend vacios.' } else { Fail 'WEB-EMPTY' "$($empty.Count) archivo(s) de frontend tienen cero bytes." }

Write-Host "`nDictamen Web: fallas=$fails advertencias=$warns" -ForegroundColor Cyan
if ($fails -gt 0) { exit 1 } else { exit 0 }
