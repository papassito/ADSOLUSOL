# ============================================================
# AUDITOR NUMERICO DE MODULOS - GRADO NASA (MISSION-CRITICAL)
# MODO SOLO LECTURA FORENSE - TOLERANCIA CERO
#
# Uso:
#   .\scripts\audit\CALIFICADOR_MODULOS.ps1
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
try {
    [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
} catch {}
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ------------------------------------------------------------
# CONFIGURACION
# ------------------------------------------------------------

$ExtensionesCodigo = @(
    ".cs",
    ".razor",
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".sql"
)

$ExtensionesTest = @(
    "test",
    "tests",
    "spec"
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
    "_audit",
    "BackUP",
    "backup",
    ".tmp_build",
    "custom-code-editor",
    "mi-nuevo-editor"
)

$ExcluirRegex = "[\\/](?:" + (($ExcluirDirectorios | ForEach-Object { [regex]::Escape($_) }) -join "|") + ")(?:[\\/]|$)"

# Localizar la raíz autoritativa de la solución
$targetRoot = (Resolve-Path $Ruta).Path
$curr = $targetRoot
while ($curr -and -not (Test-Path (Join-Path $curr "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $curr
    if ($parent -eq $curr) { break }
    $curr = $parent
}
if (Test-Path (Join-Path $curr "ADSOLUSOL.sln")) { $targetRoot = $curr }

# ------------------------------------------------------------
# FUNCIONES
# ------------------------------------------------------------

function Es-DirectorioExcluido {
    param([string]$Nombre)
    if ($Nombre -like ".audit*") { return $true }

    return $ExcluirDirectorios -contains $Nombre
}

function Es-ArchivoCodigo {
    param([System.IO.FileInfo]$Archivo)

    return $ExtensionesCodigo -contains $Archivo.Extension.ToLower()
}

function Es-Test {
    param([System.IO.FileInfo]$Archivo)
    $nombre = $Archivo.BaseName.ToLower()
    $ruta   = $Archivo.FullName.ToLower()
    if ($ruta -match '[\\/]tests?[\\/]') { return $true }
    if ($nombre -match '(tests?$|\.tests?|\.specs?|facts?)') { return $true }
    return $false
}

function Comprobar-CoberturaTests {
    param(
        [System.IO.DirectoryInfo]$Modulo,
        [System.IO.FileInfo[]]$TestsLocales,
        [string]$TargetRoot
    )

    if ($TestsLocales.Count -gt 0) {
        return $true
    }

    if (($Modulo.FullName -match '[\\/]tests[\\/]') -or ($Modulo.Name -match '(?i)Tests?$')) {
        return $true
    }

    # Comprobación dura de cobertura: ¿algún proyecto en tests/ referencia explícitamente a este módulo?
    $csprojModulo = Get-ChildItem -LiteralPath $Modulo.FullName -Filter "*.csproj" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($csprojModulo -and (Test-Path (Join-Path $TargetRoot "tests"))) {
        $testCsprojs = Get-ChildItem -LiteralPath (Join-Path $TargetRoot "tests") -Filter "*.csproj" -Recurse -File -ErrorAction SilentlyContinue
        foreach ($tcp in $testCsprojs) {
            $tcpContent = [System.IO.File]::ReadAllText($tcp.FullName, [System.Text.Encoding]::UTF8)
            if ($tcpContent -match [regex]::Escape($csprojModulo.Name)) {
                return $true
            }
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
        CATCH_VACIO = 0
        GENERIC_THROW = 0
        MOJIBAKE    = 0
        DOMAIN_LEAK = 0
        APP_LEAK    = 0
        UNSAFE_STATIC = 0
    }

    $rxCatchVacio = [regex]'catch\s*(\([^\)]*\))?\s*\{\s*\}'
    $rxGenericThrow = [regex]'throw\s+new\s+Exception\s*\('
    $rxMojibake = [regex]'(\u00C3[\u0080-\u00BF]|\u00E2[\u0080-\u00BF]{2})'
    $rxIllegalDomain = [regex]'using\s+(Microsoft\.AspNetCore|Microsoft\.EntityFrameworkCore|Dapper|Microsoft\.Data\.Sqlite|System\.Data\.SqlClient)'
    $rxIllegalApp = [regex]'using\s+ADSOLUSOL\.Infrastructure\b'
    $rxUnsafeStatic = [regex]'static\s+(?:List|Dictionary|HashSet|Queue|Stack)<'
    $rxPlaceholder = [regex]'(?-i:\bPLACEHOLDER\b(?!\s*[:=]))|(?i:\b(NOT IMPLEMENTED|IMPLEMENT ME|NotImplementedException)\b)'

    foreach ($archivo in $Archivos) {
        try {
            $contenido = Get-Content -LiteralPath $archivo.FullName -ErrorAction SilentlyContinue
            
            # Evitar falsos positivos en el motor de diagnóstico que inspecciona estas mismas palabras clave
            if ($archivo.Name -match "DiagnosticsEngine|CALIFICADOR") { continue }

            $raw = [System.IO.File]::ReadAllText($archivo.FullName, [System.Text.Encoding]::UTF8)
            if ($raw.Contains([char]0xFFFD) -or $rxMojibake.IsMatch($raw)) {
                $resultado.MOJIBAKE++
            }
            if ($rxCatchVacio.IsMatch($raw)) {
                $resultado.CATCH_VACIO++
            }
            if ($rxGenericThrow.IsMatch($raw)) {
                $resultado.GENERIC_THROW++
            }
            if ($archivo.FullName -match '[\\/]ADSOLUSOL\.Domain[\\/]' -and $rxIllegalDomain.IsMatch($raw)) {
                $resultado.DOMAIN_LEAK++
            }
            if ($archivo.FullName -match '[\\/]ADSOLUSOL\.Application[\\/]' -and $rxIllegalApp.IsMatch($raw)) {
                $resultado.APP_LEAK++
            }
            if ($rxUnsafeStatic.IsMatch($raw)) {
                $resultado.UNSAFE_STATIC++
            }

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
                if ($rxPlaceholder.IsMatch($linea)) {
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

    # Si el módulo no contiene archivos, reportar estado neutro sin distorsionar el promedio
    if ($archivos.Count -eq 0) {
        return [PSCustomObject]@{
            Modulo        = $Modulo.Name
            Calificacion  = 100
            Estado        = "EN DISENO"
            Archivos      = 0
            Codigo        = 0
            Tests         = 0
            Documentacion = 0
            LineasCodigo  = 0
            Vacios        = 0
            TODO          = 0; FIXME = 0; HACK = 0; Pendientes = 0; Grandes = 0
            Observaciones = "Directorio de andamiaje limpio (sin archivos)"
            OmitirPromedio = $true
        }
    }

    # ========================================================
    # PUNTUACION
    # ========================================================

    $score = 100
    $problemas = New-Object System.Collections.Generic.List[string]

    # Si el módulo es estrictamente de especificación o documentación (ej. docs)
    $esModuloDocumental = ($Modulo.Name -eq "docs") -or ($codigo.Count -eq 0 -and $documentacion.Count -gt 0)
    if ($esModuloDocumental) {
        $score = 100
    } else {
        if ($codigo.Count -eq 0) {
            $score -= 50
            $problemas.Add("Sin archivos de codigo")
        }

        if ($codigo.Count -gt 0) {
        $esModuloDeTests = ($Modulo.FullName -match '[\\/]tests[\\/]') -or ($Modulo.Name -match '(?i)Tests?$')

        if ($esModuloDeTests) {
            if ($tests.Count -eq 0) {
                $score -= 25
                $problemas.Add("Suite de pruebas sin ningun archivo de test ejecutable")
            } elseif (($tests.Count / $codigo.Count) -lt 0.30) {
                    $score -= 10
                $problemas.Add("Proporcion de pruebas insuficiente dentro de la suite de testing")
            }
        } else {
            $tieneCobertura = Comprobar-CoberturaTests -Modulo $Modulo -TestsLocales $tests -TargetRoot $targetRoot
            if (-not $tieneCobertura) {
                $score -= 20
                $problemas.Add("Sin pruebas internas ni cobertura referenciada en tests/")
                }
            }
        }

        # En soluciones .NET, la documentacion normativa esta centralizada en docs/ y README.md
        $tieneDocsGlobales = (Test-Path (Join-Path $targetRoot "docs")) -or (Test-Path (Join-Path $targetRoot "README.md"))
        if ($documentacion.Count -eq 0 -and -not $tieneDocsGlobales) {
            $score -= 10
            $problemas.Add("Sin documentacion")
        }
    }

    if ($vacios.Count -gt 0) {
        $penalizacion = [Math]::Min(20, $vacios.Count * 10)
        $score -= $penalizacion
        $problemas.Add("$($vacios.Count) archivo(s) vacio(s) de 0 bytes")
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
        $p = [Math]::Min(15, $deuda.HACK * 3)
        $score -= $p
        $problemas.Add("$($deuda.HACK) HACK")
    }

    if ($deuda.PANIC -gt 0) {
        $p = [Math]::Min(20, $deuda.PANIC * 5)
        $score -= $p
        $problemas.Add("$($deuda.PANIC) invocacion(es) panic()")
    }

    if ($deuda.PLACEHOLDER -gt 0) {
        $p = [Math]::Min(25, $deuda.PLACEHOLDER * 5)
        $score -= $p
        $problemas.Add("$($deuda.PLACEHOLDER) stub(s) / implementacion(es) incompleta(s)")
    }

    if ($deuda.CATCH_VACIO -gt 0) {
        $p = [Math]::Min(25, $deuda.CATCH_VACIO * 10)
        $score -= $p
        $problemas.Add("$($deuda.CATCH_VACIO) bloque(s) catch silencioso(s) (violacion fail-closed)")
    }

    if ($deuda.GENERIC_THROW -gt 0) {
        $p = [Math]::Min(20, $deuda.GENERIC_THROW * 5)
        $score -= $p
        $problemas.Add("$($deuda.GENERIC_THROW) throw de System.Exception generico")
    }

    if ($deuda.DOMAIN_LEAK -gt 0) {
        $score -= 30
        $problemas.Add("Fuga arquitectonica critica: Capa Domain acoplada a infraestructura/database")
    }

    if ($deuda.APP_LEAK -gt 0) {
        $score -= 25
        $problemas.Add("Fuga arquitectonica critica: Capa Application acoplada a Infrastructure concreta")
    }

    if ($deuda.UNSAFE_STATIC -gt 0) {
        $p = [Math]::Min(20, $deuda.UNSAFE_STATIC * 10)
        $score -= $p
        $problemas.Add("$($deuda.UNSAFE_STATIC) coleccion(es) estatica(s) mutable(s) insegura(s)")
    }

    if ($deuda.MOJIBAKE -gt 0) {
        $p = [Math]::Min(20, $deuda.MOJIBAKE * 10)
        $score -= $p
        $problemas.Add("$($deuda.MOJIBAKE) archivo(s) con corrupcion UTF-8 / Mojibake")
    }

    if ($archivosGrandes -gt 0) {
        $p = [Math]::Min(20, $archivosGrandes * 10)
        $score -= $p
        $problemas.Add("$archivosGrandes archivo(s) >800 lineas (violacion NASA Rule 3 / SRP)")
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

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "     AUDITOR NUMERICO DE MODULOS (.NET 8 / C#)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proyecto: $targetRoot" -ForegroundColor White
Write-Host ""

if (-not (Test-Path -LiteralPath $targetRoot)) {
    Write-Host "ERROR: La ruta no existe." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Buscar modulos arquitectonicos (src/ y tests/)
# ------------------------------------------------------------

$modulos = @()
if (Test-Path (Join-Path $targetRoot "src")) {
    $modulos += Get-ChildItem -LiteralPath (Join-Path $targetRoot "src") -Directory -ErrorAction SilentlyContinue |
        Where-Object { -not (Es-DirectorioExcluido $_.Name) }
}
if (Test-Path (Join-Path $targetRoot "tests")) {
    $modulos += Get-ChildItem -LiteralPath (Join-Path $targetRoot "tests") -Directory -ErrorAction SilentlyContinue |
        Where-Object { -not (Es-DirectorioExcluido $_.Name) }
}

if ($modulos.Count -eq 0) {
    $modulos = @(Get-ChildItem -LiteralPath $targetRoot -Directory -ErrorAction SilentlyContinue | Where-Object { -not (Es-DirectorioExcluido $_.Name) })
}
if ($modulos.Count -eq 0) { $modulos = @(Get-Item -LiteralPath $targetRoot) }

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

$modulosCalificables = @($resultados | Where-Object { -not $_.OmitirPromedio })
if ($modulosCalificables.Count -eq 0) {
    $modulosCalificables = $resultados
}

$promedio = [Math]::Round(
    (
        $modulosCalificables |
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
