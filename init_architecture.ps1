# PowerShell script to initialize the ADSOLUSOL Software Architecture (Onion Pattern)
$ErrorActionPreference = "Stop"

$basePath = "src"

# Definición de la estructura de directorios alineada con ONION, MOTOR, ORCHESTA y MARKETING-BRAIN
$directories = @(
    # Capa de Dominio (Núcleo del negocio: Entidades, interfaces y reglas de negocio puras)
    "$basePath/ADSOLUSOL.Domain/Entities",
    "$basePath/ADSOLUSOL.Domain/ValueObjects",
    "$basePath/ADSOLUSOL.Domain/Interfaces",
    "$basePath/ADSOLUSOL.Domain/Exceptions",
    "$basePath/ADSOLUSOL.Domain/Internal",

    # Capa de Aplicación (Casos de uso del sistema, lógica de aplicación)
    "$basePath/ADSOLUSOL.Application/Services",
    "$basePath/ADSOLUSOL.Application/Features",
    "$basePath/ADSOLUSOL.Application/Interfaces",
    "$basePath/ADSOLUSOL.Application/Internal",

    # Capa de Infraestructura (Persistencia, APIs externas, Integraciones y Seguridad)
    "$basePath/ADSOLUSOL.Infrastructure/Persistence",
    "$basePath/ADSOLUSOL.Infrastructure/ExternalServices/MarketingApi",
    "$basePath/ADSOLUSOL.Infrastructure/ExternalServices/MarketingBrain",
    "$basePath/ADSOLUSOL.Infrastructure/Security",
    "$basePath/ADSOLUSOL.Infrastructure/Internal",

    # Motor de Ejecución (Componente MOTOR independiente)
    "$basePath/ADSOLUSOL.Motor/Engine",
    "$basePath/ADSOLUSOL.Motor/Strategies",

    # Orquestador (Componente ORCHESTA para flujos de IA)
    "$basePath/ADSOLUSOL.Orchestrator/Flows",
    "$basePath/ADSOLUSOL.Orchestrator/Coordinators",

    # Capa de Presentación (API de entrada y controladores)
    "$basePath/ADSOLUSOL.Presentation.Api/Controllers",
    "$basePath/ADSOLUSOL.Presentation.Api/Middleware",

    # Capa de Entrada por Consola / CLI (Cmd)
    "$basePath/ADSOLUSOL.Presentation.Cmd",
    "$basePath/ADSOLUSOL.Presentation.Cmd/Commands"
)

# Definición de todos los archivos clave de la arquitectura (completamente vacíos)
$files = @(
    # Solución global
    "$basePath/ADSOLUSOL.sln",

    # Archivos de proyecto (.csproj) vacíos
    "$basePath/ADSOLUSOL.Domain/ADSOLUSOL.Domain.csproj",
    "$basePath/ADSOLUSOL.Application/ADSOLUSOL.Application.csproj",
    "$basePath/ADSOLUSOL.Infrastructure/ADSOLUSOL.Infrastructure.csproj",
    "$basePath/ADSOLUSOL.Motor/ADSOLUSOL.Motor.csproj",
    "$basePath/ADSOLUSOL.Orchestrator/ADSOLUSOL.Orchestrator.csproj",
    "$basePath/ADSOLUSOL.Presentation.Api/ADSOLUSOL.Presentation.Api.csproj",
    "$basePath/ADSOLUSOL.Presentation.Cmd/ADSOLUSOL.Presentation.Cmd.csproj",

    # Archivos del Dominio
    "$basePath/ADSOLUSOL.Domain/Entities/Campaign.cs",
    "$basePath/ADSOLUSOL.Domain/ValueObjects/AdContent.cs",
    "$basePath/ADSOLUSOL.Domain/Interfaces/IMarketingBrainService.cs",
    "$basePath/ADSOLUSOL.Domain/Exceptions/DomainException.cs",

    # Archivos de la Aplicación
    "$basePath/ADSOLUSOL.Application/Services/CampaignService.cs",
    "$basePath/ADSOLUSOL.Application/Interfaces/IAppDbContext.cs",

    # Archivos de Infraestructura
    "$basePath/ADSOLUSOL.Infrastructure/Persistence/AppDbContext.cs",
    "$basePath/ADSOLUSOL.Infrastructure/ExternalServices/MarketingApi/MarketingApiClient.cs",
    "$basePath/ADSOLUSOL.Infrastructure/ExternalServices/MarketingBrain/MarketingBrainClient.cs",

    # Archivos del Motor de Ejecución
    "$basePath/ADSOLUSOL.Motor/Engine/ExecutionEngine.cs",
    "$basePath/ADSOLUSOL.Motor/Strategies/ExecutionStrategy.cs",

    # Archivos del Orquestador
    "$basePath/ADSOLUSOL.Orchestrator/Flows/IaOrchestrationFlow.cs",
    "$basePath/ADSOLUSOL.Orchestrator/Coordinators/FlowCoordinator.cs",

    # Archivos de la API de Presentación
    "$basePath/ADSOLUSOL.Presentation.Api/Controllers/CampaignController.cs",
    "$basePath/ADSOLUSOL.Presentation.Api/Middleware/ExceptionMiddleware.cs",
    "$basePath/ADSOLUSOL.Presentation.Api/Program.cs",
    "$basePath/ADSOLUSOL.Presentation.Api/appsettings.json",

    # Archivos de la Consola de Presentación (Cmd)
    "$basePath/ADSOLUSOL.Presentation.Cmd/Program.cs",
    "$basePath/ADSOLUSOL.Presentation.Cmd/appsettings.json",
    "$basePath/ADSOLUSOL.Presentation.Cmd/Commands/StartEngineCommand.cs",
    "$basePath/ADSOLUSOL.Presentation.Cmd/Commands/SyncCampaignsCommand.cs",

    # Archivos de Documentación y Fases vacíos (sin código)
    "docs/decisions/DECISIONS.md",
    "docs/decisions/ADR-001.md",
    "docs/evidence/EVIDENCE.md",
    "phases/PHASE-1.md",
    "phases/PHASE-2.md",
    "phases/PHASE-3.md"
)

Write-Host "Iniciando creación de la arquitectura de software (ONION) para ADSOLUSOL..." -ForegroundColor Cyan

# 1. Crear directorios
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "[+] Creado y preparado: $dir" -ForegroundColor Green
    } else {
        Write-Host "[.] El directorio ya existe: $dir" -ForegroundColor Gray
    }
}

# 2. Crear todos los archivos vacíos (0 bytes, sin código)
foreach ($file in $files) {
    $parentDir = Split-Path -Parent $file
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
        Write-Host "[+] Archivo vacío creado: $file" -ForegroundColor Yellow
    } else {
        Write-Host "[.] El archivo ya existe: $file" -ForegroundColor Gray
    }
}

Write-Host "`n¡Estructura física y archivos arquitectónicos inicializados completamente en blanco!" -ForegroundColor Magenta