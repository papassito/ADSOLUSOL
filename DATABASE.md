# ADSOLUSOL 2027 — Esquema de Base de Datos y Ledger

**Motor Borde/Pruebas:** SQLite (`adsolusol.db`)  
**Motor Consolidado/Federado:** PostgreSQL 16+  
**Precisión Monetaria:** `DECIMAL(18,4)` obligatoria (prohibido `float`/`double`).

---

## 1. Esquema Relacional de Entidades

### Tabla `Campaigns`
| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `Id` | BIGINT | PK, AUTO_INCREMENT | Identificador único de campaña. |
| `TenantId` | VARCHAR(64) | NOT NULL, INDEX | Identificador del anunciante/nodo dueño. |
| `Name` | VARCHAR(255) | NOT NULL | Nombre descriptivo de la campaña. |
| `Status` | VARCHAR(32) | NOT NULL | `SCHEDULED`, `ACTIVE`, `PAUSED`, `COMPLETED`. |
| `Budget` | DECIMAL(18,4) | NOT NULL, CHECK (>0) | Techo presupuestario contratado. |
| `BudgetSpent` | DECIMAL(18,4) | NOT NULL, DEFAULT 0 | Saldo total acumulado debitado. |
| `CostPerMille`| DECIMAL(18,4) | NOT NULL, CHECK (>=0) | Tarifa por cada 1,000 impresiones. |
| `CostPerClick`| DECIMAL(18,4) | NOT NULL, CHECK (>=0) | Tarifa por cada clic verificado. |
| `StartDate` | TIMESTAMP | NOT NULL | Inicio de vigencia temporal. |
| `EndDate` | TIMESTAMP | NOT NULL | Fin de vigencia temporal. |
| `CreatedAt` | TIMESTAMP | NOT NULL | Registro de auditoría temporal. |

---

### Tabla `Placements`
| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `Id` | BIGINT | PK, AUTO_INCREMENT | Identificador del espacio publicitario. |
| `Code` | VARCHAR(64) | NOT NULL, UNIQUE | Código mnemónico (`HEADER_LEADERBOARD`). |
| `Description` | VARCHAR(255) | NULL | Ubicación o detalles de visualización. |
| `Width` | INT | NOT NULL | Ancho requerido en píxeles. |
| `Height` | INT | NOT NULL | Alto requerido en píxeles. |
| `IsActive` | BOOLEAN | NOT NULL, DEFAULT TRUE | Estado operativo del espacio. |

---

### Tabla `Creatives`
| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `Id` | BIGINT | PK, AUTO_INCREMENT | Identificador del anuncio creativo. |
| `TenantId` | VARCHAR(64) | NOT NULL, INDEX | Nodo/Tenant propietario del asset. |
| `Title` | VARCHAR(255) | NOT NULL | Texto principal o alt-text del anuncio. |
| `ImageUrl` | VARCHAR(1024)| NOT NULL | URL del recurso visual (First-Party CDN).|
| `TargetUrl` | VARCHAR(1024)| NOT NULL | Enlace de aterrizaje validado (HTTPS). |
| `IsActive` | BOOLEAN | NOT NULL, DEFAULT TRUE | Disponibilidad para rotación. |

---

### Tabla `AdEvents` (Ledger Inmutable de Telemetría)
| Columna | Tipo | Restricciones | Descripción |
|---|---|---|---|
| `EventId` | VARCHAR(64) | PK (UUID) | Identificador único de evento (idempotencia).|
| `CampaignId` | BIGINT | NOT NULL, FK(Campaigns)| Campaña asociada al evento. |
| `PlacementId`| BIGINT | NOT NULL, FK(Placements)| Espacio donde se sirvió. |
| `CreativeId` | BIGINT | NOT NULL, FK(Creatives) | Creativo expuesto o interactuado. |
| `EventType` | VARCHAR(32) | NOT NULL | `IMPRESSION`, `CLICK`. |
| `Cost` | DECIMAL(18,4) | NOT NULL | Costo liquidado en este evento. |
| `Timestamp` | TIMESTAMP | NOT NULL, INDEX | Momento exacto de ocurrencia. |

---

## 2. Invariante Atómica del Ledger Presupuestario

El motor de base de datos aplica atomicidad estricta para impedir sobregiros concurrentes mediante la cláusula:

```sql
UPDATE Campaigns
SET BudgetSpent = BudgetSpent + @Cost
WHERE Id = @CampaignId
  AND Status = 'ACTIVE'
  AND (BudgetSpent + @Cost) <= Budget;
```

Si la operación afecta `0` filas, la transacción se aborta (`Rollback`) y se devuelve `HTTP 400 Insufficient Budget`, garantizando que ninguna condición de carrera viole el límite presupuestario.

---

## 3. Plan de Migración de SQLite a PostgreSQL

1. **Desarrollo y Borde:** SQLite en modo WAL (`PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;`).
2. **Persistencia Consolidada (Producción):** Configurar cadena de conexión `Npgsql` en `appsettings.Production.json`.
3. **Ejecución de Migraciones EF Core:**
```powershell
dotnet ef database update --project src/ADSOLUSOL.Infrastructure --startup-project src/ADSOLUSOL.Presentation.Api
```