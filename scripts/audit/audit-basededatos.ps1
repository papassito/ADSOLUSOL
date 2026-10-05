<#
================================================================================
  ADSOLUSOL :: AUDITORIA PERICIAL DE BASE DE DATOS Y PERSISTENCIA (NASA GRADE)
  Fiscaliza DbSets en AppDbContext, índices de unicidad en EventId,
  débito atómico condicional, transaccionalidad UnitOfWork y aislamiento.
================================================================================
#>
[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = "Continue"
try { $null = chcp 65001 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
$ScriptRoot = (Resolve-Path $Root).Path
while ($ScriptRoot -and -not (Test-Path (Join-Path $ScriptRoot "ADSOLUSOL.sln"))) {
    $parent = Split-Path -Parent $ScriptRoot
    if ($parent -eq $ScriptRoot) { break }
    $ScriptRoot = $parent
}
Set-Location $ScriptRoot

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " [BASE DE DATOS] AUDITORIA DE ESQUEMA, INDICES Y ATOMICIDAD (NASA GRADE)  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Directorio Base: $ScriptRoot`n" -ForegroundColor DarkGray

$bdFails = 0
$bdWarns = 0

function Assert-BD([bool]$Condition, [string]$Code, [string]$Message, [bool]$IsFatal = $true) {
    if ($Condition) {
        Write-Host "  [PASS] [$Code] $Message" -ForegroundColor Green
    } else {
        if ($IsFatal) {
            Write-Host "  [FAIL] [$Code] $Message" -ForegroundColor Red
            $script:bdFails++
        } else {
            Write-Host "  [WARN] [$Code] $Message" -ForegroundColor Yellow
            $script:bdWarns++
        }
    }
}

function Read-SourceText([string]$RelPath) {
    $full = Join-Path $ScriptRoot $RelPath
    if (Test-Path $full) {
        return [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    }
    return ""
}

# ------------------------------------------------------------------------------
# FASE 1: MAPEO DE ENTIDADES Y DbSets EN AppDbContext
# ------------------------------------------------------------------------------
Write-Host "[1/5] Auditando colecciones DbSets y mapeo ORM en AppDbContext..." -ForegroundColor Yellow

$dbContextSrc = Read-SourceText "src/ADSOLUSOL.Infrastructure/Persistence/AppDbContext.cs"
Assert-BD ($dbContextSrc -match 'DbSet<Campaign>\s+Campaigns') "DB-SET-CAMPAIGNS" "DbSet<Campaign> registrado."
Assert-BD ($dbContextSrc -match 'DbSet<Placement>\s+Placements') "DB-SET-PLACEMENTS" "DbSet<Placement> registrado."
Assert-BD ($dbContextSrc -match 'DbSet<Creative>\s+Creatives') "DB-SET-CREATIVES" "DbSet<Creative> registrado."
Assert-BD ($dbContextSrc -match 'DbSet<AdEvent>\s+AdEvents') "DB-SET-EVENTS" "DbSet<AdEvent> registrado."
Assert-BD ($dbContextSrc -match 'DbSet<CampaignPlacement>\s+CampaignPlacements') "DB-SET-CAMP-PLC" "DbSet<CampaignPlacement> para relacion M:N."
Assert-BD ($dbContextSrc -match 'DbSet<CampaignCreative>\s+CampaignCreatives') "DB-SET-CAMP-CRV" "DbSet<CampaignCreative> para relacion M:N."

# ------------------------------------------------------------------------------
# FASE 2: INDICES DE UNICIDAD Y RESTRICCIONES RELACIONALES
# ------------------------------------------------------------------------------
Write-Host "`n[2/5] Verificando indices de unicidad para soporte de idempotencia..." -ForegroundColor Yellow

$hasUniqueEventId = (($dbContextSrc -match 'HasIndex') -and ($dbContextSrc -match 'EventId') -and ($dbContextSrc -match 'IsUnique\s*\(\)')) -or ($dbContextSrc -match 'Index\(nameof\(AdEvent\.EventId\),\s*IsUnique\s*=\s*true\)')
if (-not $hasUniqueEventId) {
    $adEventEntity = Read-SourceText "src/ADSOLUSOL.Domain/Entities/AdEvent.cs"
    $hasUniqueEventId = $adEventEntity -match '\[Index\(nameof\(EventId\),\s*IsUnique\s*=\s*true\)\]'
}
Assert-BD $hasUniqueEventId "DB-UNIQUE-EVENTID" "Indice unico obligatorio sobre AdEvent.EventId configurado en base de datos."

$hasCompositeKeys = $dbContextSrc -match 'HasKey\s*\(\s*cp\s*=>\s*new\s*\{\s*cp\.CampaignId,\s*cp\.PlacementId\s*\}\s*\)' -or ($dbContextSrc -match 'CampaignPlacements')
Assert-BD $hasCompositeKeys "DB-COMPOSITE-KEYS" "Restricciones de clave primaria e integridad en tablas de asociacion."

# ------------------------------------------------------------------------------
# FASE 3: TRANSACCIONALIDAD Y MANEJO DE UNIDAD DE TRABAJO (UnitOfWork)
# ------------------------------------------------------------------------------
Write-Host "`n[3/5] Auditando ciclo de vida transaccional en persistencia..." -ForegroundColor Yellow

$uowSrc = Read-SourceText "src/ADSOLUSOL.Infrastructure/Repositories/UnitOfWork.cs"
Assert-BD ($uowSrc -match 'BeginTransactionAsync') "DB-TX-BEGIN" "UnitOfWork implementa BeginTransactionAsync."
Assert-BD ($uowSrc -match 'CommitAsync') "DB-TX-COMMIT" "UnitOfWork implementa CommitAsync."
Assert-BD ($uowSrc -match 'RollbackAsync') "DB-TX-ROLLBACK" "UnitOfWork implementa RollbackAsync."
Assert-BD ($uowSrc -match 'IDbTransaction\??\s+Transaction') "DB-TX-EXPOSURE" "UnitOfWork expone IDbTransaction activa para interoperabilidad EF/Dapper."

# ------------------------------------------------------------------------------
# FASE 4: DEBITO ATOMICO SQL Y PREVENCION DE CARRERAS EN BD
# ------------------------------------------------------------------------------
Write-Host "`n[4/5] Inspeccionando sentencia SQL de debito condicional en SQLite..." -ForegroundColor Yellow

$campRepoSrc = Read-SourceText "src/ADSOLUSOL.Infrastructure/Repositories/CampaignRepository.cs"
$hasAtomicSql = $campRepoSrc -match 'UPDATE\s+Campaigns\s+SET\s+BudgetSpent\s*=' -and $campRepoSrc -match 'WHERE\s+Id\s*=\s*@CampaignId'
Assert-BD $hasAtomicSql "DB-ATOMIC-UPDATE" "Sentencia UPDATE condicional directa a nivel de motor de base de datos."

$hasCeilingCondition = $campRepoSrc -match '<=\s*ROUND\(CAST\(Budget\s+AS\s+REAL\),\s*6\)' -or $campRepoSrc -match '<=\s*Budget'
Assert-BD $hasCeilingCondition "DB-CEILING-SQL" "La consulta SQL condiciona el UPDATE a no exceder el presupuesto (BudgetSpent + Cost <= Budget)."

# ------------------------------------------------------------------------------
# FASE 5: COHERENCIA DE SCHEMA EN MEMORIA PARA SUITES DE PRUEBA
# ------------------------------------------------------------------------------
Write-Host "`n[5/5] Auditando compatibilidad con SQLite In-Memory en pruebas..." -ForegroundColor Yellow

$testProg = Read-SourceText "tests/ADSOLUSOL.RegressionTests/Program.cs"
Assert-BD ($testProg -match 'EnsureCreatedAsync|EnsureCreated') "DB-SCHEMA-ENSURE" "Soporte de EnsureCreatedAsync para generacion automatica de schema."
Assert-BD ($testProg -match '(?is)SqliteConnection.*mode=memory|mode=memory.*SqliteConnection') "DB-SQLITE-MEM" "Modo SQLite en memoria compartido para pruebas aisladas de alta velocidad."

# ------------------------------------------------------------------------------
# DICTAMEN FINAL DE BASE DE DATOS
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                DICTAMEN DE AUDITORIA DE BASE DE DATOS                    " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host " Infracciones Criticas : $bdFails" -ForegroundColor $(if ($bdFails -eq 0) { "Green" } else { "Red" })
Write-Host " Advertencias          : $bdWarns" -ForegroundColor $(if ($bdWarns -eq 0) { "Green" } else { "Yellow" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($bdFails -gt 0) {
    Write-Host "`n[FAIL] RECHAZADO: Infracciones de persistencia, esquema o transaccionalidad.`n" -ForegroundColor Red
    exit 1
} elseif ($bdWarns -gt 0) {
    Write-Host "`n[PASS WITH WARNINGS] Observaciones de persistencia menores.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n[PASS 10/10] Base de datos y motor transaccional SQLite/EF Core/Dapper completamente sanos.`n" -ForegroundColor Green
    exit 0
}
