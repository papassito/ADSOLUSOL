# ============================================================
# AUDITOR NUMERICO DE MODULOS
# SOLO LECTURA
#
# Uso:
#   .\CALIFICADOR_MODULOS.ps1
#
# O:
#   .\CALIFICADOR_MODULOS.ps1 -Ruta "C:\Ruta\Proyecto"
#
# Resultado:
#   Calificacion numerica 0-100 por modulo
#   Promedio general del proyecto
#
# NO MODIFICA ARCHIVOS
# NO BORRA
# NO COMPILA
# NO INSTALA
# NO HACE COMMIT
# ============================================================

param(
    [string]$Ruta = (Get-Location).Path
)

$ErrorActionPreference = "SilentlyContinue"

# ------------------------------------------------------------
# CONFIGURACION
# ------------------------------------------------------------

$ExtensionesCodigo = @(
    ".go",
    ".cs",
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".py",
    ".java",
    ".kt",
    ".rs",
    ".cpp",
    ".c",
    ".h",
    ".hpp",
    ".php",
    ".swift",
    ".sol",
    ".sql"
)

$ExtensionesTest = @(
    "_test.go",
    ".test.ts",
    ".test.tsx",
    ".spec.ts",
    ".spec.tsx",
    ".test.js",
    ".spec.js",
    "_test.py",
    "test_",
    "tests"
)

$ExcluirDirectorios = @(
    ".git",
    ".github",
    ".idea",
    ".vscode",
    "node_modules",
    "vendor",
    "dist",
    "build",
    "coverage",
    ".next",
    ".cache",
    "bin",
    "obj",
    "tmp",
    "temp",
    "custom-code-editor",
    "mi-nuevo-editor"
)

# ------------------------------------------------------------
# FUNCIONES
# ------------------------------------------------------------

function Es-DirectorioExcluido {
    param([string]$Nombre)

    return $ExcluirDirectorios -contains $Nombre
}

function Es-ArchivoCodigo {
    param([System.IO.FileInfo]$Archivo)

    return $ExtensionesCodigo -contains $Archivo.Extension.ToLower()
}

function Es-Test {
    param([System.IO.FileInfo]$Archivo)

    $nombre = $Archivo.Name.ToLower()
    $ruta   = $Archivo.FullName.ToLower()

    foreach ($patron in $ExtensionesTest) {
        if ($nombre -like "*$patron*" -or $ruta -like "*\$patron\*") {
            return $true
        }
    }

    return $false
}

function Contar-Lineas {
    param([System.IO.FileInfo[]]$Archivos)

    $total = 0

    foreach ($archivo in $Archivos) {
        try {
            $total += (Get-Content -LiteralPath $archivo.FullName -ErrorAction SilentlyContinue).Count
        }
        catch {}
    }
    return $total
}

function Buscar-DeudaTecnica {
    param([System.IO.FileInfo[]]$Archivos)

    $resultado = @{
        TODO       = 0
        FIXME      = 0
        HACK       = 0
        PANIC      = 0
        PLACEHOLDER = 0
    }

    foreach ($archivo in $Archivos) {
        try {
            $contenido = Get-Content -LiteralPath $archivo.FullName -ErrorAction SilentlyContinue
            
            # Evitar falsos positivos en el motor de diagnóstico que inspecciona estas mismas palabras clave
            if ($archivo.Name -match "DiagnosticsEngine|CALIFICADOR") { continue }

            foreach ($linea in $contenido) {
                if ($linea -match '(?i)\bTODO\b') {
                    $resultado.TODO++
                }
                if ($linea -match '(?i)\bFIXME\b') {
                    $resultado.FIXME++
                }
                if ($linea -match '(?i)\bHACK\b') {
                    $resultado.HACK++
                }
                if ($linea -match '(?i)\bpanic\s*\(') {
                    $resultado.PANIC++
                }
                if ($linea -match '(?i)PLACEHOLDER|NOT IMPLEMENTED|IMPLEMENT ME') {
                    $resultado.PLACEHOLDER++
                }
            }
        }
        catch {}
    }

    return $resultado
}

function Calificar-Modulo {
    param(
        [System.IO.DirectoryInfo]$Modulo
    )

    $archivos = Get-ChildItem `
        -LiteralPath $Modulo.FullName `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $ruta = $_.FullName
            $excluir = $false
            foreach ($dir in $ExcluirDirectorios) {
                if ($ruta -match "[\\/]$([regex]::Escape($dir))[\\/]") {
                    $excluir = $true
                    break
                }
            }
            -not $excluir
        }

    $codigo = @(
        $archivos |
        Where-Object { Es-ArchivoCodigo $_ }
    )

    $tests = @(
        $codigo |
        Where-Object { Es-Test $_ }
    )

    $vacios = @(
        $archivos |
        Where-Object { $_.Length -eq 0 }
    )

    $documentacion = @(
        $archivos |
        Where-Object {
            $_.Extension -in @(".md", ".txt", ".rst") -or
            $_.Name -match '(?i)README|ARCHITECTURE|TESTING|SECURITY|REQUIREMENTS'
        }
    )

    $lineas = Contar-Lineas $codigo
    $deuda = Buscar-DeudaTecnica $codigo
    $archivosGrandes = 0

    foreach ($archivo in $codigo) {
        try {
            $cantidad = (Get-Content -LiteralPath $archivo.FullName -ErrorAction SilentlyContinue).Count
            if ($cantidad -gt 800) {
                $archivosGrandes++
            }
        }
        catch {}
    }

    # ========================================================
    # PUNTUACION
    # ========================================================

    $score = 100
    $problemas = New-Object System.Collections.Generic.List[string]

    if ($codigo.Count -eq 0) {
        $score -= 50
        $problemas.Add("Sin archivos de codigo")
    }

    if ($vacios.Count -gt 0) {
        $penalizacion = [Math]::Min(20, $vacios.Count * 4)
        $score -= $penalizacion
        $problemas.Add("$($vacios.Count) archivo(s) vacio(s)")
    }

    if ($codigo.Count -gt 0) {
        if ($tests.Count -eq 0) {
            $score -= 15
            $problemas.Add("Sin pruebas detectadas")
        }
        else {
            $ratioTest = $tests.Count / $codigo.Count
            if ($ratioTest -lt 0.05) {
                $score -= 10
                $problemas.Add("Cobertura estructural de tests muy baja")
            }
            elseif ($ratioTest -lt 0.10) {
                $score -= 5
                $problemas.Add("Pocos archivos de pruebas")
            }
        }
    }

    if ($documentacion.Count -eq 0) {
        $score -= 10
        $problemas.Add("Sin documentacion")
    }

    if ($deuda.TODO -gt 0) {
        $p = [Math]::Min(10, $deuda.TODO)
        $score -= $p
        $problemas.Add("$($deuda.TODO) TODO")
    }

    if ($deuda.FIXME -gt 0) {
        $p = [Math]::Min(15, $deuda.FIXME * 2)
        $score -= $p
        $problemas.Add("$($deuda.FIXME) FIXME")
    }

    if ($deuda.HACK -gt 0) {
        $p = [Math]::Min(10, $deuda.HACK * 2)
        $score -= $p
        $problemas.Add("$($deuda.HACK) HACK")
    }

    if ($deuda.PLACEHOLDER -gt 0) {
        $p = [Math]::Min(20, $deuda.PLACEHOLDER * 4)
        $score -= $p
        $problemas.Add("$($deuda.PLACEHOLDER) implementacion(es) pendiente(s)")
    }

    if ($archivosGrandes -gt 0) {
        $p = [Math]::Min(10, $archivosGrandes * 2)
        $score -= $p
        $problemas.Add("$archivosGrandes archivo(s) >800 lineas")
    }

    if ($score -gt 100) { $score = 100 }
    if ($score -lt 0) { $score = 0 }

    $estado = switch ($score) {
        { $_ -ge 90 } { "EXCELENTE"; break }
        { $_ -ge 80 } { "MUY BUENO"; break }
        { $_ -ge 70 } { "BUENO"; break }
        { $_ -ge 60 } { "ACEPTABLE"; break }
        { $_ -ge 50 } { "DEBIL"; break }
        { $_ -ge 30 } { "MALO"; break }
        default { "CRITICO" }
    }

    if ($problemas.Count -eq 0) {
        $detalle = "Sin problemas estructurales detectados"
    }
    else {
        $detalle = $problemas -join "; "
    }

    return [PSCustomObject]@{
        Modulo        = $Modulo.Name
        Calificacion  = [int]$score
        Estado        = $estado
        Archivos      = $archivos.Count
        Codigo        = $codigo.Count
        Tests         = $tests.Count
        Documentacion = $documentacion.Count
        LineasCodigo  = $lineas
        Vacios        = $vacios.Count
        TODO          = $deuda.TODO
        FIXME         = $deuda.FIXME
        HACK          = $deuda.HACK
        Pendientes    = $deuda.PLACEHOLDER
        Grandes       = $archivosGrandes
        Observaciones = $detalle
    }
}

# ============================================================
# INICIO
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "     AUDITOR NUMERICO DE MODULOS - SOLO LECTURA" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proyecto: $Ruta" -ForegroundColor White
Write-Host ""

if (-not (Test-Path -LiteralPath $Ruta)) {
    Write-Host "ERROR: La ruta no existe." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Buscar modulos principales
# ------------------------------------------------------------

$modulos = @(
    Get-ChildItem `
        -LiteralPath $Ruta `
        -Directory `
        -ErrorAction SilentlyContinue |
    Where-Object {
        -not (Es-DirectorioExcluido $_.Name)
    }
)

if ($modulos.Count -eq 0) {
    $modulos = @(Get-Item -LiteralPath $Ruta)
}

$resultados = @()

foreach ($modulo in $modulos) {
    Write-Host "Analizando: $($modulo.Name)" -ForegroundColor DarkGray
    $resultado = Calificar-Modulo $modulo
    $resultados += $resultado
}

# ============================================================
# RANKING
# ============================================================

$resultados = @(
    $resultados |
    Sort-Object Calificacion -Descending
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    CALIFICACIONES" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$resultados |
Format-Table `
    Modulo,
    Calificacion,
    Estado,
    Codigo,
    Tests,
    Vacios,
    TODO,
    FIXME,
    Pendientes `
    -AutoSize

# ============================================================
# PROMEDIO GENERAL
# ============================================================

$promedio = [Math]::Round(
    (
        $resultados |
        Measure-Object `
            -Property Calificacion `
            -Average
    ).Average,
    2
)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "CALIFICACION GENERAL DEL PROYECTO: " -NoNewline

if ($promedio -ge 90) {
    Write-Host "$promedio / 100" -ForegroundColor Green
}
elseif ($promedio -ge 70) {
    Write-Host "$promedio / 100" -ForegroundColor Yellow
}
elseif ($promedio -ge 50) {
    Write-Host "$promedio / 100" -ForegroundColor DarkYellow
}
else {
    Write-Host "$promedio / 100" -ForegroundColor Red
}

Write-Host ""

# ============================================================
# DETALLE
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                 DETALLE POR MODULO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

foreach ($r in $resultados) {
    Write-Host ""
    Write-Host "[$($r.Calificacion)/100] $($r.Modulo)" -ForegroundColor White
    Write-Host "  Estado:        $($r.Estado)"
    Write-Host "  Codigo:        $($r.Codigo)"
    Write-Host "  Tests:         $($r.Tests)"
    Write-Host "  Lineas:        $($r.LineasCodigo)"
    Write-Host "  Docs:          $($r.Documentacion)"
    Write-Host "  Vacios:        $($r.Vacios)"
    Write-Host "  TODO:          $($r.TODO)"
    Write-Host "  FIXME:         $($r.FIXME)"
    Write-Host "  HACK:          $($r.HACK)"
    Write-Host "  Pendientes:    $($r.Pendientes)"
    Write-Host "  >800 lineas:   $($r.Grandes)"
    Write-Host "  Observaciones: $($r.Observaciones)"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "AUDITORIA TERMINADA - NO SE MODIFICO NINGUN ARCHIVO" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
