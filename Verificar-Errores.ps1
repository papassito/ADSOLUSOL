<#
================================================================================
  KLIK DIAGNOSTIC SUITE :: VERIFICADOR INTEGRAL DE ERRORES Y SALUD DIGITAL
  Ejecucion directa sin bloqueo:
  powershell -ExecutionPolicy Bypass -File .\Verificar-Errores.ps1
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Path = ".",
    [switch]$Fix
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

$RootPath = (Resolve-Path $Path).Path
Set-Location $RootPath

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   ORQUESTA BY KLIK :: ESCANER INTEGRAL FORENSE Y DE ERRORES     " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Directorio objetivo: $RootPath`n" -ForegroundColor DarkGray

$Global:TotalErrores = 0
$Global:TotalWarnings = 0

function Registrar-Falla {
    param(
        [string]$Modulo,
        [string]$Archivo,
        [string]$Detalle,
        [string]$Nivel = "ERROR"
    )
    if ($Nivel -eq "ERROR") {
        $Global:TotalErrores++
        Write-Host " [CRITICO] " -ForegroundColor Red -NoNewline
    } else {
        $Global:TotalWarnings++
        Write-Host " [ALERTA]  " -ForegroundColor Yellow -NoNewline
    }
    Write-Host "[$Modulo] " -ForegroundColor White -NoNewline
    Write-Host "$Archivo " -ForegroundColor Cyan -NoNewline
    Write-Host "-> $Detalle" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# 1. INSPECCION DE CODIFICACION, BOM Y MOJIBAKE
# -----------------------------------------------------------------------------
Write-Host "[1/6] Analizando Codificacion, BOM y Caracteres Corruptos (Mojibake)..." -ForegroundColor Yellow

$ArchivosTexto = Get-ChildItem -Path $RootPath -Recurse -File | Where-Object {
    $_.Extension.ToLower() -in @('.ts', '.tsx', '.go', '.cpp', '.hpp', '.json', '.md') -and
    $_.FullName -notmatch '[\\/](\.git|node_modules|build|dist|out)[\\/]'
}

foreach ($f in $ArchivosTexto) {
    $rel = $f.FullName.Replace($RootPath, "").TrimStart('\', '/')
    try {
        $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            if ($Fix) {
                [System.IO.File]::WriteAllBytes($f.FullName, $bytes[3..($bytes.Length - 1)])
                Write-Host " [REPARADO] [BOM] $rel -> UTF-8 BOM eliminado" -ForegroundColor Green
            } else {
                Registrar-Falla "ENCODING" $rel "Contiene UTF-8 BOM (puede provocar errores de parseo)"
            }
        }
    } catch {}

    $contenido = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($contenido) {
        if ($Fix -and $contenido -match "(\u00C3[\u0080-\u00BF]|\u00E2\u0088\u009E|\u00F0\u0178|\u00E2\u20AC)") {
            try {
                $enc1252 = [System.Text.Encoding]::GetEncoding(1252)
                $encUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
                $bytesFixed = $enc1252.GetBytes($contenido)
                $fixedContenido = $encUtf8.GetString($bytesFixed)
                $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                [System.IO.File]::WriteAllText($f.FullName, $fixedContenido, $utf8NoBom)
                $contenido = $fixedContenido
                Write-Host " [REPARADO] [MOJIBAKE] $rel -> Caracteres restaurados a UTF-8" -ForegroundColor Green
            } catch {}
        }

        # Patrones de mojibake expresados en secuencias Unicode ASCII puras
        if ($contenido -match "(\u00C3[\u0080-\u00BF]|\u00E2\u0088\u009E|\u00F0\u0178)") {
            Registrar-Falla "MOJIBAKE" $rel "Caracteres con codificacion corrupta detectados (tildes/simbolos deformados)" "ALERTA"
        }
    }
}

# -----------------------------------------------------------------------------
# 2. DIAGNOSTICO FRONTEND & REACT (TypeScript / TSX)
# -----------------------------------------------------------------------------
Write-Host "[2/6] Analizando Frontend, Audio Worker y Sintaxis TSX..." -ForegroundColor Yellow

$AppTsx = Join-Path $RootPath "src\App.tsx"
if (Test-Path $AppTsx) {
    $appContent = Get-Content $AppTsx -Raw -Encoding UTF8

    if ($appContent -match 'const\s+recognizedNotes\s*=\s*await\s+engine\.processOMRImage' -and 
        $appContent -match 'finally[\s\S]*?recognizedNotes\.length') {
        Registrar-Falla "TSX_SCOPE" "src/App.tsx" "Variable 'recognizedNotes' usada en bloque 'finally' fuera de su ambito lexico (Scope Error)"
    }

    # Antipatron class= en TSX
    if ($appContent -match '\bclass="') {
        Registrar-Falla "REACT_SYNTAX" "src/App.tsx" "Uso del atributo HTML 'class' en lugar de 'className'"
    }
} else {
    Registrar-Falla "ESTRUCTURA" "src/App.tsx" "Archivo principal de vista no encontrado"
}

$Bridge = Join-Path $RootPath "EngineBridge.ts"
if (Test-Path $Bridge) {
    $bridgeContent = Get-Content $Bridge -Raw -Encoding UTF8
    if ($bridgeContent -match "new SharedArrayBuffer" -and $bridgeContent -notmatch "crossOriginIsolated") {
        Registrar-Falla "CONCURRENCIA" "EngineBridge.ts" "SharedArrayBuffer instanciado sin comprobacion de crossOriginIsolated"
    }
}

# -----------------------------------------------------------------------------
# 3. DIAGNOSTICO BUNKER NATIVO C++ & SEGURIDAD DE HARDWARE
# -----------------------------------------------------------------------------
Write-Host "[3/6] Analizando Bunker Nativo C++, SMBIOS, TPM y Anti-Tamper..." -ForegroundColor Yellow

$HwidFile = Join-Path $RootPath "hwid_extractor.cpp"
if (Test-Path $HwidFile) {
    $hwContent = Get-Content $HwidFile -Raw -Encoding UTF8

    $smbiosValido = ($hwContent -match "RSMB") -or ($hwContent -match "Win32_BaseBoard")
    if (-not $smbiosValido) {
        Registrar-Falla "BUNKER_HWID" "hwid_extractor.cpp" "Falta amarre a tabla SMBIOS (identificador 'RSMB' o 'Win32_BaseBoard')"
    }

    if ($hwContent -notmatch "HMAC") {
        Registrar-Falla "BUNKER_HWID" "hwid_extractor.cpp" "Falta firma o calculo HMAC en generacion de HWID"
    }

    if ($hwContent -match "\b(strcpy|strcat|sprintf|gets)\b") {
        Registrar-Falla "SEGURIDAD_C" "hwid_extractor.cpp" "Uso de funcion C insegura de manipulacion de memoria: $($Matches[1])"
    }
} else {
    Registrar-Falla "ESTRUCTURA" "hwid_extractor.cpp" "Extractor nativo de HWID ausente"
}

$AntiTamperFile = Join-Path $RootPath "anti_tamper.cpp"
if (Test-Path $AntiTamperFile) {
    $atContent = Get-Content $AntiTamperFile -Raw -Encoding UTF8
    if ($atContent -notmatch "0x40000000") {
        Registrar-Falla "ANTI_TAMPER" "anti_tamper.cpp" "Falta comprobacion de hipervisor (firma 0x40000000)"
    }
}

$CMakeFile = Join-Path $RootPath "CMakeLists.txt"
if (Test-Path $CMakeFile) {
    $cmakeContent = Get-Content $CMakeFile -Raw -Encoding UTF8
    if ($cmakeContent -match "add_executable\s*\(\s*\w+[^)]*hwid_extractor\.cpp[^)]*anti_tamper\.cpp") {
        Registrar-Falla "CMAKE" "CMakeLists.txt" "hwid_extractor y anti_tamper agrupados en el mismo ejecutable (colision de main)"
    }
}

# -----------------------------------------------------------------------------
# 4. DIAGNOSTICO DE INTEGRIDAD EN EL NUCLEO GO (core/)
# -----------------------------------------------------------------------------
Write-Host "[4/6] Analizando Nucleo Go (core/): Sintaxis, Aislamiento y DSP..." -ForegroundColor Yellow

$CoreDir = Join-Path $RootPath "core"
if (-not (Test-Path $CoreDir)) {
    Registrar-Falla "ESTRUCTURA" "core/" "Directorio del nucleo Go no existe"
} else {
    $GoFiles = Get-ChildItem -Path $CoreDir -Recurse -Filter "*.go" | Where-Object { $_.FullName -notmatch '[\\/]vendor[\\/]' }
    foreach ($gf in $GoFiles) {
        $relGf = $gf.FullName.Replace($RootPath, "").TrimStart('\', '/')
        $c = Get-Content $gf.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($gf.Length -eq 0) {
            Registrar-Falla "GO_SYNTAX" $relGf "Archivo Go vacío (0 bytes)"
        }
        if ($c -match "\btif\b") {
            Registrar-Falla "GO_SYNTAX" $relGf "Token corrupto 'tif' detectado"
        }
        $backticks = ($c.ToCharArray() | Where-Object { $_ -eq [char]96 }).Count
        if ($backticks % 2 -ne 0) {
            Registrar-Falla "GO_SYNTAX" $relGf "Cantidad impar de backticks (sin cerrar)"
        }
    }

    # Validar constantes fundamentales
    $PitchFile = Join-Path $CoreDir "domain\pitch.go"
    if (Test-Path $PitchFile) {
        $pContent = Get-Content $PitchFile -Raw -Encoding UTF8
        if ($pContent -notmatch "440\.0" -or $pContent -notmatch "A4MIDINote\s*=\s*69") {
            Registrar-Falla "DSP_PITCH" "core/domain/pitch.go" "Desviacion de afinacion ISO 16 (se requiere A4 = 440 Hz, MIDI 69)"
        }
    }

    $NoteFile = Join-Path $CoreDir "domain\note.go"
    if (Test-Path $NoteFile) {
        $nContent = Get-Content $NoteFile -Raw -Encoding UTF8
        if ($nContent -notmatch "PPQN\s*int64\s*=\s*960") {
            Registrar-Falla "DSP_TIME" "core/domain/note.go" "Base temporal corrupta (se exige resolucion indivisible de 960 PPQN)"
        }
    }

    $ContainerFile = Join-Path $CoreDir "infrastructure\container.go"
    if (Test-Path $ContainerFile) {
        $contContent = Get-Content $ContainerFile -Raw -Encoding UTF8
        if ($contContent -notmatch "KLIKORQ1" -or $contContent -notmatch "cipher\.NewGCM" -or $contContent -notmatch "ed25519\.Sign") {
            Registrar-Falla "SEGURIDAD_VAULT" "core/infrastructure/container.go" "Especificacion criptografica incompleta en contenedor .orquesta"
        }
    }
}

# -----------------------------------------------------------------------------
# 5. ARCHIVOS HUERFANOS Y NECROSIS
# -----------------------------------------------------------------------------
Write-Host "[5/6] Buscando Archivos Temporales, Huerfanos o Necrosis..." -ForegroundColor Yellow

$Necroticos = Get-ChildItem -Path $RootPath -Recurse -File -Include "*.tmp","*.bak","*.orig","*~","*.swp" -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch '[\\/](\.git|node_modules|build|dist|out)[\\/]'
}
foreach ($n in $Necroticos) {
    $relN = $n.FullName.Replace($RootPath, "").TrimStart('\', '/')
    if ($Fix) {
        Remove-Item $n.FullName -Force -ErrorAction SilentlyContinue
        Write-Host " [REPARADO] [NECROSIS] $relN -> Archivo temporal eliminado" -ForegroundColor Green
    } else {
        Registrar-Falla "NECROSIS" $relN "Archivo temporal o respaldo residual presente en repositorio" "ALERTA"
    }
}

# -----------------------------------------------------------------------------
# 6. RESUMEN DIAGNÓSTICO FINAL
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[6/6] Consolidando Dictamen..." -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                    DICTAMEN DEL DIAGNOSTICO                      " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

if ($Global:TotalErrores -eq 0 -and $Global:TotalWarnings -eq 0) {
    Write-Host "`n[10/10 PERFECTO] El proyecto esta libre de fallos criticos y advertencias." -ForegroundColor Green
    Write-Host "Listo para certificacion y ejecucion de Junta Medica.`n" -ForegroundColor DarkGray
    exit 0
} elseif ($Global:TotalErrores -eq 0) {
    Write-Host "`n[APROBADO CON ADVERTENCIAS] 0 errores criticos, $($Global:TotalWarnings) advertencias menores." -ForegroundColor Yellow
    Write-Host "Se recomienda atender las advertencias para alcanzar la calificacion 10/10.`n" -ForegroundColor DarkGray
    exit 0
} else {
    Write-Host "`n[REPROBADO] Se encontraron $($Global:TotalErrores) errores criticos y $($Global:TotalWarnings) advertencias." -ForegroundColor Red
    Write-Host "Corrige los puntos listados arriba antes de correr la auditoria final.`n" -ForegroundColor DarkGray
    exit 1
}