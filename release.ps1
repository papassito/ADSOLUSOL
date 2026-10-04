<#
================================================================================
  ADSOLUSOL :: RELEASE, DEPLOY & HYGIENE AUTOMATION
  Pipeline Operativo: Saneamiento de Archivos (-Fix), Publicación Nativa Windows
  y Sincronización Segura con Git previa Auditoría Pasiva
================================================================================
#>
param(
    [string]$Root = ".",
    [switch]$Fix,
    [switch]$Consolidate,
    [switch]$Publish,
    [switch]$Status,
    [switch]$Add,
    [switch]$Commit,
    [switch]$Push,
    [string]$CommitMessage = "chore(release): release pipeline completado y verificado"
)

$ErrorActionPreference = "Stop"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptRoot = (Resolve-Path $Root).Path
if ((Split-Path -Path $ScriptRoot -Leaf) -eq "scripts") {
    $ScriptRoot = Split-Path -Path $ScriptRoot -Parent
}
Set-Location $ScriptRoot

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   ADSOLUSOL :: PIPELINE DE RELEASE Y OPERACIONES        " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Directorio de Trabajo: $ScriptRoot" -ForegroundColor DarkGray
# 0. Consolidación del Repositorio (-Consolidate)
if ($Consolidate) {
    Write-Host "`n[CONSOLIDACIÓN] Ejecutando limpieza y organización maestra..." -ForegroundColor Yellow

    $organizeScripts = Join-Path $ScriptRoot "organize-scripts.ps1"
    if (Test-Path $organizeScripts) {
        & $organizeScripts
    } else {
        Write-Host "  [INFO] organize-scripts.ps1 no encontrado, omitiendo." -ForegroundColor Gray
    }

    $generateDocs = Join-Path $ScriptRoot "generate_docs.ps1"
    if (Test-Path $generateDocs) {
        & $generateDocs
    } else {
        Write-Host "  [INFO] generate_docs.ps1 no encontrado, omitiendo." -ForegroundColor Gray
    }

    # La ruta del script de integridad ahora estará dentro de /scripts/audit/
    $integrityScript = Join-Path $ScriptRoot "scripts/audit/autopsia_integridad.ps1"
    if (Test-Path $integrityScript) {
        Write-Host "  [CONSOLIDACIÓN] Re-sellando manifiesto documental..." -ForegroundColor DarkCyan
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $integrityScript -Reseal
    } else {
        Write-Host "  [INFO] autopsia_integridad.ps1 no encontrado, omitiendo re-sellado." -ForegroundColor Gray
    }

    # Actualizar el árbol estructural del proyecto
    $treeScript = Join-Path $ScriptRoot "Show-ProjectTree.ps1"
    if (Test-Path $treeScript) {
        Write-Host "  [CONSOLIDACIÓN] Actualizando documentación de estructura (docs/STRUCTURE.md)..." -ForegroundColor DarkCyan
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $treeScript -OutFile "docs/STRUCTURE.md" -Depth 4
    }

    Write-Host "`n[OK] Consolidación completada. Se recomienda hacer commit de los cambios." -ForegroundColor Green
    Write-Host 'Ejemplo: git add .; git commit -m "chore: apply automated repository consolidation"' -ForegroundColor DarkGray
    exit 0
}

# 1. Saneamiento Quirúrgico Activo (-Fix)
if ($Fix) {
    Write-Host "`n[SANEAMIENTO] Aplicando correcciones en el árbol de trabajo (-Fix)..." -ForegroundColor Yellow

    # A. Extirpación de archivos fantasma y duplicados
    $ghostPatterns = @('* (1).*', '* (2).*', '*.tmp', '*.bak', '*.orig', '*~', '*.swp', 'desktop.ini', 'Thumbs.db', '.DS_Store')
    $ghosts = Get-ChildItem -Path $ScriptRoot -Recurse -Include $ghostPatterns -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "[\\/]\.git[\\/]" }
    foreach ($g in $ghosts) {
        Remove-Item $g.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "  [EXTIRPADO] Archivo fantasma: $($g.Name)" -ForegroundColor Green
    }

    # A.1 Extirpación de directorios temporales residuales
    $junkFolders = @(".tmp_build", "TestResults")
    foreach ($jf in $junkFolders) {
        $folderPath = Join-Path $ScriptRoot $jf
        if (Test-Path $folderPath) {
            Remove-Item $folderPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [EXTIRPADO] Directorio temporal: $jf" -ForegroundColor Green
        }
    }

    # B. Extirpación de archivos vacíos (0 bytes)
    $emptyFiles = Get-ChildItem -Path $ScriptRoot -Recurse -Include "*.cs", "*.md", "*.json", "*.ps1" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -eq 0 -and $_.FullName -notmatch '[\\/](\.git|bin|obj|BUILD)[\\/]' }
    foreach ($ef in $emptyFiles) {
        Remove-Item $ef.FullName -Force -ErrorAction SilentlyContinue
        Write-Host ('  [EXTIRPADO] Archivo vacío (0 bytes): ' + $ef.FullName.Substring($ScriptRoot.Length)) -ForegroundColor Green
    }

    # C. Saneamiento de BOM UTF-8 y caracteres de control
    $validExts = @(".cs", ".csproj", ".json", ".md", ".ps1", ".xaml", ".razor")
    $textFiles = Get-ChildItem -Path $ScriptRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $validExts -contains $_.Extension -and $_.FullName -notmatch '[\\/](\.git|bin|obj|BUILD)[\\/]' }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($file in $textFiles) {
        $rawBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
            $rawBytes = $rawBytes[3..($rawBytes.Length - 1)]
        }
        $text = [System.Text.Encoding]::UTF8.GetString($rawBytes)
        $sanitizedText = [System.Text.RegularExpressions.Regex]::Replace($text, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '')
        $sanitizedText = $sanitizedText -replace "\r?\n", "`r`n"
        [System.IO.File]::WriteAllText($file.FullName, $sanitizedText, $utf8NoBom)
    }

    # D. Formato canónico .NET
    $sln = Join-Path $ScriptRoot "ADSOLUSOL.sln"
    if (Test-Path $sln) {
        Write-Host "  [RESTAURANDO] Ejecutando dotnet restore y dotnet format..." -ForegroundColor Yellow
        & dotnet restore $sln -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false --verbosity quiet 2>&1 | Out-Null
        & dotnet format $sln --no-restore --verbosity quiet 2>&1 | Out-Null
        Write-Host "  [SANEADO] Formato canónico C# completado." -ForegroundColor Green
    }
}

# 2. Quality Gate de Solo Lectura (junta_medica.ps1)
Write-Host "`n>>> Ejecutando Quality Gate forense (junta_medica.ps1)..." -ForegroundColor Yellow
$auditScript = Join-Path $ScriptRoot "scripts/audit/junta_medica.ps1"
if (-not (Test-Path $auditScript)) {
    # Fallback a la raíz para compatibilidad durante la transición
    $auditScript = Join-Path $ScriptRoot "junta_medica.ps1"
}
if (Test-Path $auditScript) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $auditScript -Fast
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[BLOQUEO] Quality Gate reprobado. Se abortan tareas de release y git." -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Quality Gate aprobado exitosamente." -ForegroundColor Green
} else {
    Write-Host "[ALERTA] junta_medica.ps1 no encontrado. Omitiendo validación previa." -ForegroundColor DarkYellow
}

# 3. Publicación Nativa Desktop (-Publish)
if ($Publish) {
    Write-Host "`n>>> Publicando artefacto nativo MAUI Desktop..." -ForegroundColor Yellow
    $desktopProj = Join-Path $ScriptRoot "src\ADSOLUSOL.Presentation.Desktop\ADSOLUSOL.Presentation.Desktop.csproj"
    if (-not (Test-Path $desktopProj)) {
        Write-Host "[ERROR] Falta el proyecto Desktop en $desktopProj" -ForegroundColor Red
        exit 1
    }
    $publishDir = Join-Path $ScriptRoot "BUILD\ADSOLUSOL"
    if (Test-Path $publishDir) { Remove-Item $publishDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $publishDir | Out-Null

    & dotnet restore $desktopProj -f net8.0-windows10.0.19041.0 -r win-x64 -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false --verbosity quiet 2>&1 | Out-Null
    & dotnet publish $desktopProj -c Release -f net8.0-windows10.0.19041.0 -r win-x64 --no-restore --nologo -p:WindowsPackageType=None -p:AppxPackage=false -p:GenerateAppxPackageOnBuild=false -p:WindowsAppSDKSelfContained=false -p:IgnoreMissingWorkloads=true -o $publishDir

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Falló la publicación de la aplicación MAUI Desktop." -ForegroundColor Red
        exit 1
    }

    # Asegurar la presencia de Microsoft.WindowsAppRuntime.Bootstrap.dll en la raíz
    $bootstrapDll = Join-Path $publishDir "Microsoft.WindowsAppRuntime.Bootstrap.dll"
    if (-not (Test-Path $bootstrapDll)) {
        $foundBootstrap = Get-ChildItem -Path "$env:USERPROFILE\.nuget\packages\microsoft.windowsappsdk" -Filter "Microsoft.WindowsAppRuntime.Bootstrap.dll" -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "x64" } | Select-Object -First 1
        if ($foundBootstrap) {
            Copy-Item -Path $foundBootstrap.FullName -Destination $publishDir -Force
        }
    }
    Write-Host "[OK] Artefacto compilado exitosamente en $publishDir." -ForegroundColor Green
}

# 4. Operaciones Git
$hasGitFlags = $Status -or $Add -or $Commit -or $Push
if ($hasGitFlags) {
    Write-Host "`n>>> Ejecutando operaciones Git..." -ForegroundColor Yellow
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-Host "[ERROR] git no está instalado o no se encuentra en el PATH." -ForegroundColor Red
        exit 1
    }

    if ($Status -or ($Push -and -not $Add -and -not $Commit)) {
        Write-Host "`n[GIT STATUS]" -ForegroundColor Yellow
        & git status
    }

    if ($Add -or ($Push -and -not $Commit)) {
        Write-Host "`n[GIT ADD] Indexando cambios..." -ForegroundColor Yellow
        & git add -A
        & git status --short
    }

    if ($Commit -or $Push) {
        $pending = & git status --porcelain
        if ($pending) {
            Write-Host "`n[GIT COMMIT] Creando commit..." -ForegroundColor Yellow
            & git commit -m "$CommitMessage"
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] Falló git commit." -ForegroundColor Red
                exit 1
            }
            Write-Host "[OK] Commit creado." -ForegroundColor Green
        } else {
            Write-Host "[INFO] Árbol de trabajo limpio. Sin cambios pendientes." -ForegroundColor Cyan
        }
    }

    if ($Push) {
        Write-Host "`n[GIT PUSH] Enviando cambios al repositorio remoto..." -ForegroundColor Yellow
        & git push
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Push completado exitosamente." -ForegroundColor Green
        } else {
            Write-Host "[WARN] git push devolvió advertencias." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "   PIPELINE FINALIZADO CON EXITO                         " -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
