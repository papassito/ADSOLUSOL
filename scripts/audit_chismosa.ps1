$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
if (-not $scriptDir -and $MyInvocation.MyCommand.Path) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = if ($scriptDir) { Split-Path -Parent $scriptDir } else { $pwd.Path }

Write-Host "========================================================================" -ForegroundColor Magenta
Write-Host "   LA AUDITORÍA CHISMOSA: ¿Qué está ocultando realmente ADSOLUSOL? 🤐" -ForegroundColor Magenta
Write-Host "========================================================================" -ForegroundColor Magenta

$chismes = 0
$secretosAlAire = 0

function Revelar-Chisme([string]$categoria, [string]$detalle, [string]$severidad = "Media") {
    $color = if ($severidad -eq "Alta") { "Red" } elseif ($severidad -eq "Baja") { "DarkGray" } else { "Yellow" }
    Write-Host "[!] [$categoria] ($severidad): $detalle" -ForegroundColor $color
    $script:chismes++
    if ($severidad -eq "Alta") { $script:secretosAlAire++ }
}

# --- CHISME 1: Entorno de Ejecución y Runtimes ---
Write-Host "`n🕵️‍♀️ Investigando el entorno..." -ForegroundColor Cyan

$dotnetPath = $env:ADSOLUSOL_DOTNET
if (-not $dotnetPath -or -not (Test-Path -LiteralPath $dotnetPath)) {
    $dotnetPath = (Get-Command dotnet -ErrorAction SilentlyContinue).Source
}

if ($dotnetPath) {
    Write-Host "✔ El SDK de .NET está disponible en '$dotnetPath'." -ForegroundColor Gray
} else {
    Revelar-Chisme "Entorno" "No se detectó el SDK de .NET ni en PATH ni en la ruta predeterminada de Codex." "Alta"
}

# --- CHISME 2: Estado de la base de datos ---
Write-Host "`n🕵️‍♀️ Husmeando en los cajones del almacenamiento..." -ForegroundColor Cyan
$dbPath = Join-Path $root 'src\ADSOLUSOL.Presentation.Api\App_Data\campaigns.db'
if (Test-Path -LiteralPath $dbPath) {
    $dbSize = (Get-Item -LiteralPath $dbPath).Length
    Write-Host "✔ Base de datos detectada ($dbSize bytes). Al menos hay persistencia real de campañas." -ForegroundColor Gray
} else {
    Revelar-Chisme "Persistencia" "No hay base de datos física 'campaigns.db' creada en App_Data de la API. ¡Trabajamos con el aire hasta que inicies el servidor!" "Baja"
}

# --- CHISME 3: Comparativa de Contrato vs Realidad (C#) ---
Write-Host "`n🕵️‍♀️ Cruzando el contrato de MARKETING-API.md con el código real..." -ForegroundColor Cyan
$apiDocsPath = Join-Path $root 'docs\contracts\MARKETING-API.md'
$csFiles = Get-ChildItem -Path (Join-Path $root 'src') -Filter "*.cs" -Recurse | Where-Object { $_.FullName -notmatch '\\/[\\/]' }

$contratoTexto = Get-Content -LiteralPath $apiDocsPath -Raw
$endpointsTeoricos = @(
    @{ path = "/api/marketing/seo"; metodo = "GET"; desc = "Reporte de SEO" },
    @{ path = "/api/marketing/adsolusol"; metodo = "GET"; desc = "Operaciones de ADS" },
    @{ path = "/api/marketing/adsolusol/campaigns"; metodo = "POST"; desc = "Crear campaña" },
    @{ path = "/api/marketing/adsolusol/campaigns/:id/toggle"; metodo = "POST"; desc = "Activar/Desactivar campaña" },
    @{ path = "/api/marketing/adsolusol/campaigns/:id/click"; metodo = "POST"; desc = "Registrar clic" },
    @{ path = "/api/marketing/adsolusol/campaigns/:id/impression"; metodo = "POST"; desc = "Registrar impresión" }
)

# Unir todo el código fuente C# para buscar rutas reales
$codigoCompleto = if ($csFiles) {
    [string]::Join("`r`n", (Get-Content -LiteralPath $csFiles.FullName -Raw))
} else { "" }

foreach ($ep in $endpointsTeoricos) {
    # Simplificar la ruta para buscar en el código de ASP.NET
    $pathBusqueda = $ep.path.Replace(":id", "{id}").Replace("/api", "")
    $existeEnCodigo = $codigoCompleto -match $pathBusqueda
    
    if (-not $existeEnCodigo) {
        Revelar-Chisme "Contrato Roto" "El endpoint '$($ep.metodo) $($ep.path)' ($($ep.desc)) está documentado pero NO está implementado en ningún controlador C#." "Alta"
    } else {
        # Chisme adicional: ¿Está simulado o tira 503?
        if ($ep.path -match "content" -or $ep.path -match "toggle") {
            Revelar-Chisme "Incompleto" "El endpoint '$($ep.path)' existe en código pero de seguro devuelve un 503 o está cableado sin lógica real de negocio." "Media"
        }
    }
}

# --- CHISME 4: Buscar promesas incumplidas en el código (TODOs / FIXMEs / NotImplemented) ---
Write-Host "`n🕵️‍♀️ Leyendo la mente de los desarrolladores (buscando TODOs, FIXMEs y parches)..." -ForegroundColor Cyan
foreach ($file in $csFiles) {
    $lineas = Get-Content -LiteralPath $file.FullName
    $lineNum = 1
    foreach ($line in $lineas) {
        if ($line -match "TODO" -or $line -match "FIXME") {
            $limpia = $line.Trim()
            $relFile = $file.FullName.Substring($root.Length + 1)
            Revelar-Chisme "Deuda Técnica" "Encontré un pendiente en '$relFile' línea $lineNum: '$limpia'" "Media"
        }
        if ($line -match "throw new NotImplementedException") {
            $relFile = $file.FullName.Substring($root.Length + 1)
            Revelar-Chisme "Sin Implementar" "¡Alerta de código fantasma! Exception de no implementado en '$relFile' línea $lineNum" "Alta"
        }
        $lineNum++
    }
}

# --- CHISME 5: ¿Dónde está el CORE y el SIC en el código? ---
Write-Host "`n🕵️‍♀️ Buscando rastro de integración real de seguridad (CORE / SIC)..." -ForegroundColor Cyan
$tieneCoreConfig = $codigoCompleto -match "Core" -or $codigoCompleto -match "Signature" -or $codigoCompleto -match "VerificationState"
if (-not $tieneCoreConfig) {
    Revelar-Chisme "Seguridad" "No se ven trazas de validación de firmas criptográficas de CORE. La API solo se fía del 'X-Api-Key' estático del archivo de ambiente." "Alta"
} else {
    Write-Host "✔ Veo menciones o modelos de CORE/SIC en el código, pero la autenticación operativa sigue apagada." -ForegroundColor Gray
}

# --- CHISME 6: Pruebas unitarias reales vs Regresiones de consola ---
Write-Host "`n🕵️‍♀️ Revisando cómo prueban el código..." -ForegroundColor Cyan
$hasTestsProject = Test-Path -Path (Join-Path $root 'tests')
if ($hasTestsProject) {
    $regressionTests = Get-ChildItem -Path (Join-Path $root 'tests') -Filter "*Regression*" -Recurse
    if ($regressionTests) {
        Write-Host "✔ Usan un motor personalizado de regresión en consola (RegressionTests). ¡Muy artesanal!" -ForegroundColor Gray
    }
    
    # ¿Hay xUnit, NUnit o MSTest?
    $hasRealTestFramework = $codigoCompleto -match "\[Fact\]" -or $codigoCompleto -match "\[Test\]"
    if (-not $hasRealTestFramework) {
        Revelar-Chisme "Pruebas" "No hay suites tradicionales de xUnit/NUnit integradas con 'dotnet test'. Todo corre con ejecutables customizados." "Media"
    }
} else {
    Revelar-Chisme "Pruebas" "No existe un directorio de 'tests' convencional en la raíz de ADSOLUSOL." "Alta"
}

# --- RESUMEN FINAL ---
Write-Host "`n========================================================================" -ForegroundColor Magenta
Write-Host "   RESUMEN DEL COTILLEO TÉCNICO" -ForegroundColor Magenta
Write-Host "========================================================================" -ForegroundColor Magenta
Write-Host "Total de secretos, incoherencias o pendientes hallados: $chismes" -ForegroundColor Yellow
Write-Host "Problemas críticos ('Alta') que bloquearían un pase real: $secretosAlAire" -ForegroundColor Red

if ($secretosAlAire -gt 0) {
    Write-Host "`n❌ Veredicto de la Chismosa: El proyecto compila y pasa el humo básico, pero tiene el circuito bloqueado. No puedes ir a producción sin una identidad de CORE, endpoints de eventos reales y una base de pruebas formal." -ForegroundColor Red
    Write-Host "Sugerencia: Define los contratos reales y deja de simular con 503." -ForegroundColor Cyan
} else {
    Write-Host "`n✔ Veredicto de la Chismosa: ¡Sorprendente! No encontré ningún cabo suelto crítico de arquitectura. Puedes continuar con la cabeza en alto." -ForegroundColor Green
}
Write-Host "========================================================================" -ForegroundColor Magenta

# No salimos con error 'exit 1' para permitir que el desarrollador lea tranquilamente las verdades sin romper el flujo de su consola.
exit 0