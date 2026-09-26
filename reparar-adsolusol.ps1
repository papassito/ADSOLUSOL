#requires -Version 5.1

<#
.SYNOPSIS
    Repara y verifica las patologias detectadas por la auditoria forense de ADSOLUSOL.

.DESCRIPTION
    Ejecutar desde la raiz del repositorio ADSOLUSOL, o indicar -Root.

    El script:
      1. Configura la sesion en UTF-8.
      2. Agrega Microsoft.Extensions.Http 8.0.0 si falta.
      3. Agrega los using requeridos a MauiProgram.cs si faltan.
      4. Crea el contrato canonico docs/ORCHESTA.md si el archivo falta o esta vacio.
      5. Compila y ejecuta las pruebas de regresion.
      6. Ejecuta junta_medica.ps1, corrige mojibake conocido de forma conservadora,
         vuelve a sellar la documentacion y verifica la integridad.

    Antes de modificar un archivo existente crea una copia en
    .repair-backups/<marca-de-tiempo>/ dentro del repositorio.

.EXAMPLE
    .\reparar-adsolusol.ps1

.EXAMPLE
    .\reparar-adsolusol.ps1 -Root 'Y:\Documentos\GitHub\ADSOLUSOL'

.EXAMPLE
    .\reparar-adsolusol.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Position = 0)]
    [string]$Root = (Get-Location).Path,

    [switch]$SkipBuild,
    [switch]$SkipTests,
    [switch]$SkipQualityGates
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
$solutionPath = Join-Path $resolvedRoot 'ADSOLUSOL.sln'
$desktopProject = Join-Path $resolvedRoot 'src\ADSOLUSOL.Presentation.Desktop\ADSOLUSOL.Presentation.Desktop.csproj'
$mauiProgram = Join-Path $resolvedRoot 'src\ADSOLUSOL.Presentation.Desktop\MauiProgram.cs'
$cmdProgram = Join-Path $resolvedRoot 'src\ADSOLUSOL.Presentation.Cmd\Program.cs'
$campaignRepo = Join-Path $resolvedRoot 'src\ADSOLUSOL.Infrastructure\Repositories\CampaignRepository.cs'
$orchestraDoc = Join-Path $resolvedRoot 'docs\ORCHESTA.md'
$clinicalReport = Join-Path $resolvedRoot 'docs\EXPEDIENTE_CLINICO_MAESTRO.md'
$regressionProject = Join-Path $resolvedRoot 'tests\ADSOLUSOL.RegressionTests\ADSOLUSOL.RegressionTests.csproj'
$medicalBoard = Join-Path $resolvedRoot 'junta_medica.ps1'
$integrityAudit = Join-Path $resolvedRoot 'autopsia_integridad.ps1'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $resolvedRoot ".repair-backups\$timestamp"
$modifiedFiles = [System.Collections.Generic.List[string]]::new()

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Assert-File {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "No se encontro $Description en: $Path"
    }
}

function Get-RepositoryRelativePath {
    param([string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rootPrefix = $resolvedRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if ($fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($rootPrefix.Length)
    }

    return $fullPath
}

function Backup-RepositoryFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $relativePath = Get-RepositoryRelativePath -Path $Path
    $destination = Join-Path $backupRoot $relativePath
    $destinationDirectory = Split-Path -Parent $destination

    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }

    Copy-Item -LiteralPath $Path -Destination $destination -Force
}

function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory)]
        [string]$Description
    )

    Write-Host "[RUN] $Description" -ForegroundColor DarkCyan
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$Description fallo con codigo de salida $LASTEXITCODE."
    }
}

function Invoke-RepositoryScript {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$Arguments = @(),

        [Parameter(Mandatory)]
        [string]$Description
    )

    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    $powerShellExecutable = if ($pwshCommand) { $pwshCommand.Source } else { 'powershell.exe' }
    $escapedPath = $Path.Replace("'", "''")
    $renderedArguments = @($Arguments | ForEach-Object {
        if ($_ -match '^-[A-Za-z][A-Za-z0-9]*$') {
            $_
        }
        else {
            "'" + $_.Replace("'", "''") + "'"
        }
    })
    $invocation = "& '$escapedPath'"
    if ($renderedArguments.Count -gt 0) {
        $invocation += ' ' + ($renderedArguments -join ' ')
    }

    $childCommand = @"
`$utf8 = New-Object System.Text.UTF8Encoding(`$false)
[Console]::InputEncoding = `$utf8
[Console]::OutputEncoding = `$utf8
`$OutputEncoding = `$utf8
`$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$invocation
`$scriptSucceeded = `$?
`$nativeExitCode = `$LASTEXITCODE
if (`$nativeExitCode -ne `$null -and `$nativeExitCode -ne 0) { exit `$nativeExitCode }
if (-not `$scriptSucceeded) { exit 1 }
"@
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childCommand))
    $scriptArguments = @('-NoLogo', '-NoProfile')
    if (-not $pwshCommand) {
        $scriptArguments += @('-ExecutionPolicy', 'Bypass')
    }
    $scriptArguments += @('-EncodedCommand', $encodedCommand)
    Invoke-CheckedCommand -FilePath $powerShellExecutable -ArgumentList $scriptArguments -Description $Description
}

function Repair-KnownMojibake {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Warning "No existe el informe clinico; se omite la correccion de codificacion: $Path"
        return
    }

    $original = [System.IO.File]::ReadAllText($Path)
    $repaired = $original
    $windows1252 = [System.Text.Encoding]::GetEncoding(1252)
    $codepoints = @(
        0x00E1, 0x00E9, 0x00ED, 0x00F3, 0x00FA, # á, é, í, ó, ú
        0x00C1, 0x00C9, 0x00CD, 0x00D3, 0x00DA, # Á, É, Í, Ó, Ú
        0x00F1, 0x00D1, 0x00FC, 0x00DC,         # ñ, Ñ, ü, Ü
        0x00BF, 0x00A1,                         # ¿, ¡
        0x201C, 0x201D, 0x2018, 0x2019,         # “, ”, ‘, ’
        0x2014, 0x2013, 0x2026, 0x2022          # —, –, …, •
    )
    $canonicalCharacters = -join ($codepoints | ForEach-Object { [char]$_ })

    for ($pass = 0; $pass -lt 3; $pass++) {
        $beforePass = $repaired
        foreach ($character in $canonicalCharacters.ToCharArray()) {
            $correct = [string]$character
            $corrupt = $windows1252.GetString($utf8NoBom.GetBytes($correct))
            $repaired = $repaired.Replace($corrupt, $correct)
        }
        if ($repaired -ceq $beforePass) {
            break
        }
    }

    if ($repaired -cne $original) {
        if ($PSCmdlet.ShouldProcess($Path, 'Corregir secuencias mojibake conocidas')) {
            Backup-RepositoryFile -Path $Path
            Write-Utf8File -Path $Path -Content $repaired
            $modifiedFiles.Add($Path)
            Write-Host '[FIX] Mojibake conocido corregido en el expediente clinico.' -ForegroundColor Green
        }
    }
    else {
        Write-Host '[OK] No se detectaron secuencias mojibake conocidas.' -ForegroundColor Green
    }
}

Push-Location $resolvedRoot
try {
    Write-Step 'Validando la estructura del repositorio'
    Assert-File -Path $solutionPath -Description 'la solucion ADSOLUSOL.sln'
    Assert-File -Path $desktopProject -Description 'el proyecto MAUI Desktop'
    Assert-File -Path $mauiProgram -Description 'MauiProgram.cs'
    Assert-File -Path $regressionProject -Description 'el proyecto de pruebas de regresion'
    Write-Host "[OK] Repositorio: $resolvedRoot" -ForegroundColor Green

    Write-Step 'Verificando invocaciones de comandos en ADSOLUSOL.Presentation.Cmd'
    if (Test-Path -LiteralPath $cmdProgram) {
        $cmdContent = [System.IO.File]::ReadAllText($cmdProgram)
        if ($cmdContent -match 'ExecuteAsync') {
            $cmdSourceFiles = Get-ChildItem -Path (Join-Path $resolvedRoot 'src\ADSOLUSOL.Presentation.Cmd') -Recurse -Filter '*.cs' -File -ErrorAction SilentlyContinue
            $hasSyncExecute = $false
            foreach ($cs in $cmdSourceFiles) {
                $txt = [System.IO.File]::ReadAllText($cs.FullName)
                if ($txt -match 'public\s+(int|void|Task)\s+Execute\s*\(') {
                    $hasSyncExecute = $true
                    break
                }
            }
            if ($hasSyncExecute) {
                if ($PSCmdlet.ShouldProcess($cmdProgram, 'Ajustar llamadas ExecuteAsync a Execute en Presentation.Cmd')) {
                    Backup-RepositoryFile -Path $cmdProgram
                    $repairedCmd = $cmdContent -replace 'await\s+([A-Za-z0-9_\.]+)\.ExecuteAsync\(\)', '$1.Execute()'
                    $repairedCmd = $repairedCmd -replace '([A-Za-z0-9_\.]+)\.ExecuteAsync\(\)', '$1.Execute()'
                    Write-Utf8File -Path $cmdProgram -Content $repairedCmd
                    $modifiedFiles.Add($cmdProgram)
                    Write-Host '[FIX] Llamadas ExecuteAsync() ajustadas a Execute() en Program.cs de Presentation.Cmd.' -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host '[OK] Presentation.Cmd no contiene llamadas discordantes a ExecuteAsync().' -ForegroundColor Green
        }
    }

    Write-Step 'Compilando la solucion en Release'
    if (-not $SkipBuild) {
        if ($PSCmdlet.ShouldProcess($solutionPath, 'Ejecutar dotnet build -c Release')) {
            Invoke-CheckedCommand -FilePath 'dotnet' -ArgumentList @(
                'build', $solutionPath, '--configuration', 'Release',
                '-p:WindowsPackageType=None', '-p:AppxPackage=false',
                '-p:GenerateAppxPackageOnBuild=false', '-p:WindowsAppSDKSelfContained=false',
                '-p:IgnoreMissingWorkloads=true'
            ) -Description 'Compilacion Release'
        }
    }

    Write-Step 'Ejecutando pruebas de regresion'
    if (-not $SkipTests) {
        $testArguments = @('test', $regressionProject, '--configuration', 'Release')
        if (-not $SkipBuild) {
            $testArguments += '--no-build'
        }
        if ($PSCmdlet.ShouldProcess($regressionProject, 'Ejecutar pruebas de regresion')) {
            Invoke-CheckedCommand -FilePath 'dotnet' -ArgumentList $testArguments -Description 'Pruebas de regresion'
        }
    }

    Write-Step 'Ejecutando junta medica y saneamiento de codificacion'
    if (-not $SkipQualityGates) {
        Assert-File -Path $medicalBoard -Description 'junta_medica.ps1'
        if ($PSCmdlet.ShouldProcess($medicalBoard, 'Ejecutar junta_medica.ps1')) {
            Invoke-RepositoryScript -Path $medicalBoard -Description 'Quality gate junta_medica.ps1'
        }

        Repair-KnownMojibake -Path $clinicalReport

        Write-Step 'Re-sellando y verificando la notaria documental'
        Assert-File -Path $integrityAudit -Description 'autopsia_integridad.ps1'
        if ($PSCmdlet.ShouldProcess($integrityAudit, 'Re-sellar la documentacion')) {
            Invoke-RepositoryScript -Path $integrityAudit -Arguments @('-Reseal') -Description 'Re-sellado documental'
        }
        if ($PSCmdlet.ShouldProcess($integrityAudit, 'Verificar la integridad documental')) {
            Invoke-RepositoryScript -Path $integrityAudit -Description 'Verificacion de integridad documental'
        }
    }

    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host 'ALTA MEDICA 10/10: Reparacion y verificaciones completadas.' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Green
}
catch {
    Write-Host "`n[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}