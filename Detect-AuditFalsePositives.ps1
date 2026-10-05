<#
.SYNOPSIS
    Detecta posibles falsos positivos en los informes de auditoría.
.DESCRIPTION
    Compara hallazgos del informe maestro con el árbol real del proyecto.
    No modifica archivos.
#>
[CmdletBinding()]
param(
    [string]$ReportPath = "",
    [string]$OutputPath = ".\_audit\audit_false_positives.txt"
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $PSScriptRoot } else { (Get-Location).Path }
$root = (Resolve-Path $scriptDir).Path
while ($root -and -not (Test-Path (Join-Path $root "ADSOLUSOL.sln"))) {
    $parent = Split-Path $root -Parent
    if ($parent -eq $root) { break }
    $root = $parent
}
Set-Location $root

# Auto-detección del informe más reciente si no se especificó o no existe el default
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $auditDir = Join-Path $root "_audit"
    $latestReport = Get-ChildItem -Path $auditDir -File -Filter "*.txt" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "audit_false_positives.txt" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestReport) {
        $reportFullPath = $latestReport.FullName
    } else {
        $reportFullPath = Join-Path $root "_audit\informe.txt"
    }
} else {
    $reportFullPath = if ([System.IO.Path]::IsPathRooted($ReportPath)) { $ReportPath } else { Join-Path $root $ReportPath }
}

$outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $root $OutputPath }

if (-not (Test-Path -LiteralPath $reportFullPath)) {
    Write-Error "No se localizó ningún informe de auditoría en: $reportFullPath"
    exit 1
}

function Read-SharedText([string]$filePath) {
    if (-not (Test-Path -LiteralPath $filePath)) { return "" }
    try {
        $stream = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8)
        $text = $reader.ReadToEnd()
        $reader.Dispose()
        $stream.Dispose()
        return $text
    } catch {
        return (Get-Content -LiteralPath $filePath -Raw -ErrorAction SilentlyContinue)
    }
}

$report = Read-SharedText $reportFullPath
$findings = [System.Collections.Generic.List[string]]::new()
$confirmed = [System.Collections.Generic.List[string]]::new()

# 1. Comprueba rutas que el informe afirma que faltan.
$pathTokens = [regex]::Matches($report, '(?im)(?:falta(?:n)?|no existe|no encontrado|missing)[^\r\n]*')
foreach ($token in $pathTokens) {
    $relativePaths = [regex]::Matches($token.Value, '(?:src|docs|scripts|tests)[\\/][A-Za-z0-9_.\\/()-]+')
    foreach ($match in $relativePaths) {
        $candidate = ($match.Value -replace '/', '\').TrimEnd('.', ',', ':', ';', ')', ']', '"', "'")
        if (Test-Path -LiteralPath (Join-Path $root $candidate)) {
            $findings.Add("El informe afirma ausencia, pero la ruta existe: $candidate")
        }
    }
}

# 2. Comprueba errores históricos causados por Root vacío.
if ($report -match '(?im)Resolve-Path.*cadena vacía|Resolve-Path.*empty|Join-Path.*nulo') {
    $scripts = Get-ChildItem -LiteralPath (Join-Path $root "scripts\audit") -Filter "*.ps1" -File
    foreach ($script in $scripts) {
        $content = Get-Content -LiteralPath $script.FullName -Raw
        if ($content -match '\[string\]\$Root\s*=\s*"\."' -or $content -match 'IsNullOrWhiteSpace\(\$Root\)') {
            $findings.Add("El informe registró error por Root vacío, pero $($script.Name) ya cuenta con fallback.")
        }
    }
}

# 3. Reejecuta auditores que el informe maestro marcó como FAIL.
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
$psExe = if ($pwshCmd) { $pwshCmd.Source } else { "powershell.exe" }

$failAuditors = [regex]::Matches($report, '(?im)^\s*(?:>>>\s*\[)?(?:Fase[^\r\n]*\]?\s*->?\s*)?([A-Za-z0-9_.-]+\.ps1)\s+(?:\[?FAIL\]?|FAIL|\bFAIL\b)')
$processed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($match in $failAuditors) {
    $name = $match.Groups[1].Value
    if (-not $processed.Add($name)) { continue }
    if ($name -eq "Detect-AuditFalsePositives.ps1") { continue }

    $path = Get-ChildItem -LiteralPath (Join-Path $root "scripts\audit") -Filter $name -File -ErrorAction SilentlyContinue
    if (-not $path) {
        $path = Get-ChildItem -LiteralPath $root -Filter $name -File -ErrorAction SilentlyContinue
    }
    if ($path) {
        $outputRaw = & $psExe -NoProfile -ExecutionPolicy Bypass -File $path.FullName 2>&1
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
        $outputText = ($outputRaw | Out-String)

        $hasPassText = ($outputText -match '(?im)\[PASS\]' -or $outputText -match '(?im)APROBADO' -or $outputText -match '(?im)10/10')
        $hasFailText = ($outputText -match '(?im)\[FAIL\]' -or $outputText -match '(?im)RECHAZADO' -or $outputText -match '(?im)(?:Infracciones|Fallas|Errores)\w*\s*:\s*[1-9]')

        if ($exitCode -eq 0 -and (-not $hasFailText -or $hasPassText)) {
            $findings.Add("El informe marca $name como FAIL, pero al reejecutar emite veredicto PASS (ExitCode: 0).")
        }
        elseif ($exitCode -ne 0 -and $hasPassText -and -not $hasFailText) {
            $findings.Add("El informe marca $name como FAIL; al reejecutar emite PASS en texto pero ExitCode=$exitCode (falso positivo por código de salida).")
        }
        else {
            $confirmed.Add("$name continúa reproduciendo fallo verificable (ExitCode: $exitCode).")
        }
    }
}

# 4. Detecta contradicciones semánticas entre auditores en el mismo informe
$antagonisms = @(
    @{
        Tema = "Máquina de estados vs Validación de transiciones"
        AfirmacionA = '(?i)LOGIC-STATE-MACHINE.*PASS'
        AfirmacionB = '(?i)CAMPAIGN-TRANSITIONS.*El servicio no valida transiciones'
        Detalle = "audit-logica valida la máquina de estados, pero audit-campanas no detectó el patrón de transición."
    },
    @{
        Tema = "Gobernanza Multi-Tenant vs Exigencia de Aislamiento"
        AfirmacionA = '(?i)REQUIREMENTS\.md.*Libre de requisitos multi-tenant'
        AfirmacionB = '(?i)CAMPAIGN-ASSIGNMENT-TENANT.*Las asociaciones no muestran comprobaci'
        Detalle = "Gobernanza descartó REQ-TEN-, pero audit-campanas aún fiscaliza comprobación explícita de tenant en asociaciones."
    },
    @{
        Tema = "Ciclo Transaccional vs Persistencia"
        AfirmacionA = '(?i)FIN-TX-LIFECYCLE.*PASS'
        AfirmacionB = '(?i)DB-TX-COMMIT.*FAIL'
        Detalle = "audit-finanzas confirma el ciclo transaccional completo, pero audit-basededatos reporta fallo en Commit."
    },
    @{
        Tema = "Codificación UTF-8 vs Alerta de Mojibake"
        AfirmacionA = '(?i)WEB-ENCODING.*PASS.*100% limpia'
        AfirmacionB = '(?i)WEB-MOJIBAKE.*FAIL'
        Detalle = "audit-web reporta codificación 100% limpia y fallo de mojibake en la misma ejecución."
    }
)

foreach ($ant in $antagonisms) {
    if ($report -match $ant.AfirmacionA -and $report -match $ant.AfirmacionB) {
        $findings.Add("[CONTRADICCION] $($ant.Tema): $($ant.Detalle)")
    }
}

# 5. Comprueba imports relativos del frontend únicamente si el informe los reportó como rotos
$hasBrokenImportNotice = $report -match '(?i)import.*no resuelto|WEB-BROKEN-IMPORT'
if ($hasBrokenImportNotice) {
    $app = Join-Path $root "src\ADSOLUSOL.Presentation.Web\src\App.tsx"
    if (Test-Path -LiteralPath $app) {
        $appText = Read-SharedText $app
        foreach ($import in [regex]::Matches($appText, "from\s+['""](\.[^'""]+)['""]")) {
            $relative = $import.Groups[1].Value
            if ($report -match [regex]::Escape($relative)) {
                $base = Join-Path (Split-Path $app -Parent) $relative
                $exists = @("$base.ts", "$base.tsx", "$base.js", "$base.jsx", $base) |
                    Where-Object { Test-Path -LiteralPath $_ }
                if ($exists) {
                    $findings.Add("El informe reportó import roto pero existe en disco: $relative")
                } else {
                    $confirmed.Add("Import roto confirmado (no existe en disco): $relative")
                }
            }
        }
    }
}

$outputDirectory = Split-Path -Parent $outputFullPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("DETECCION DE FALSOS POSITIVOS DE AUDITORIA")
$lines.Add("Raiz: $root")
$lines.Add("Informe analizado: $reportFullPath")
$lines.Add("Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("")
$lines.Add("POSIBLES FALSOS POSITIVOS: $($findings.Count)")
foreach ($item in $findings) { $lines.Add("  [REVISAR] $item") }
$lines.Add("")
$lines.Add("HALLAZGOS REPRODUCIBLES: $($confirmed.Count)")
foreach ($item in $confirmed) { $lines.Add("  [CONFIRMADO] $item") }

[System.IO.File]::WriteAllLines($outputFullPath, $lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "[REPORT] $outputFullPath" -ForegroundColor DarkGray
Write-Host "[INFO] Posibles falsos positivos: $($findings.Count)" -ForegroundColor Cyan
Write-Host "[INFO] Hallazgos reproducibles: $($confirmed.Count)" -ForegroundColor Cyan
if ($findings.Count -gt 0) { exit 2 } else { exit 0 }
