# PowerShell script to reorganize and clean up the ADSOLUSOL Canonical Library structure
$ErrorActionPreference = "Stop"

# 1. Archivos redundantes/duplicados a eliminar
$duplicates = @(
    "LIBRARY (1).md",
    "MANIFEST (1).md"
)

# 2. Mapa de reubicación lógica (Origen -> Destino)
$reorganizationMap = @{
    # Archivos que van directamente en la raíz (según el Manifiesto)
    "docs/COMPONENTS.md"      = "COMPONENTS.md"
    "docs/MAP.md"             = "MAP.md"
    "docs/REQUIREMENTS.md"    = "REQUIREMENTS.md"
    
    # Carpeta: docs/architecture/
    "docs/ADSOLUSOL.md"       = "docs/architecture/ADSOLUSOL.md"
    "docs/AI.md"              = "docs/architecture/AI.md"
    "docs/AI-AD.md"           = "docs/architecture/AI-AD.md"
    "docs/MOTOR.md"           = "docs/architecture/MOTOR.md"
    "docs/ONION.md"           = "docs/architecture/ONION.md"
    "docs/ORCHESTA.md"        = "docs/architecture/ORCHESTA.md"
    "docs/SITEMAP.md"         = "docs/architecture/SITEMAP.md"
    
    # Carpeta: docs/contracts/
    "docs/CONTRACTS.md"       = "docs/contracts/CONTRACTS.md"
    "docs/MARKETING-API.md"   = "docs/contracts/MARKETING-API.md"
    
    # Carpeta: docs/business/
    "docs/CAMPAIGN.md"        = "docs/business/CAMPAIGN.md"
    "docs/MARKETING.md"       = "docs/business/MARKETING.md"
    "docs/SEO.md"             = "docs/business/SEO.md"
    
    # Carpeta: docs/security/
    "docs/INTEGRITY.md"       = "docs/security/INTEGRITY.md"
    
    # Carpeta: docs/operations/
    "docs/VALIDATE.md"        = "docs/operations/VALIDATE.md"
    
    # Carpeta: docs/integration/
    "docs/MARKETING-BRAIN.md" = "docs/integration/MARKETING-BRAIN.md"
}

Write-Host "Iniciando reubicación de la estructura ADSOLUSOL..." -ForegroundColor Cyan

# Eliminar archivos duplicados generados por descargas o conflictos
foreach ($dup in $duplicates) {
    if (Test-Path $dup) {
        Remove-Item -Path $dup -Force
        Write-Host "[-] Eliminado archivo redundante: $dup" -ForegroundColor Yellow
    }
}

# Procesar la reubicación a sus respectivas carpetas arquitectónicas
foreach ($source in $reorganizationMap.Keys) {
    $destination = $reorganizationMap[$source]
    
    if (Test-Path $source) {
        # Asegurar que el directorio destino de la subcarpeta exista
        $destDir = Split-Path -Path $destination
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            Write-Host "[+] Creada subcarpeta: $destDir" -ForegroundColor Blue
        }
        
        # Mover archivo de forma segura sobreescribiendo si ya existiera
        Move-Item -Path $source -Destination $destination -Force
        Write-Host "[M] Reubicado: $source -> $destination" -ForegroundColor Green
    } else {
        Write-Host "[!] El archivo origen ya no existe o ya fue movido: $source" -ForegroundColor Gray
    }
}

Write-Host "`n¡Estructura reubicada y limpia con éxito!" -ForegroundColor Magenta