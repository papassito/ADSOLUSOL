# AD SOLUSOL — Components

**Estado:** PRE-SELLO / clasificación contra implementación actual

## Componentes implementados o parciales

| Componente | Estado observado | Evidencia funcional en código |
|---|---|---|
| Campaign Manager | IMPLEMENTED / PARTIAL | `CampaignService`, `CampaignRepository`, `CampaignsController` |
| Placement Registry | IMPLEMENTED / PARTIAL | `PlacementRepository`, `PlacementsController` |
| Creative Manager | IMPLEMENTED / PARTIAL | `CreativeRepository`, `CreativesController` |
| Assignment Layer | IMPLEMENTED / PARTIAL | `AssignmentRepository`, `AssignmentsController` |
| Delivery Engine | IMPLEMENTED / PARTIAL | `AdServingService`, `ServeController` |
| Event Processing | IMPLEMENTED / PARTIAL | `EventProcessingService`, `AdEventRepository` |
| Metrics Engine | IMPLEMENTED / PARTIAL | `MetricsService` |
| Budget Engine | IMPLEMENTED | `BudgetService`, actualización condicional de presupuesto |
| SQLite Persistence | IMPLEMENTED / DEV-CONFIGURED | `AppDbContext`, repositorios, `EnsureCreated()` |
| Ed25519 Verifier | IMPLEMENTED COMPONENT | `CoreSignatureVerifier` |
| Signature Middleware | IMPLEMENTED_BUT_NOT_WIRED | `SignatureVerificationMiddleware`; no está en `Program.cs` |
| React/Vite UI | IMPLEMENTED SOURCE / NOT PACKAGED | `ADSOLUSOL.Presentation.Web` |
| Health Check | IMPLEMENTED | `GET /api/health` |

## Componentes incompletos o no verificados

| Componente | Estado observado |
|---|---|
| Tenant Resolver / Authorization | NOT_IMPLEMENTED en el pipeline actual |
| Marketing Brain integration | NOT_IMPLEMENTED / UNVERIFIED; cliente actual devuelve disponibilidad sintética y telemetría no-op |
| SIC integration | PARTIAL; Health consulta SIC, no existe integración completa de negocio |
| ORCHESTA adapter | PLANNED / no verificado en runtime actual |
| AI / AI AD | PLANNED / diseño documental |
| SEO adapter | PLANNED / fuera del núcleo ADS |
| Production UI hosting | NOT_IMPLEMENTED todavía |
| Production DB path/schema upgrades | NOT_IMPLEMENTED todavía |
| Installer | NOT_IMPLEMENTED todavía |

## Invariantes

- Authentication != Authorization.
- Capability != Permission.
- Recommendation != Execution.
- `DISCONNECTED` no equivale a disponibilidad positiva ni a cero actividad.
- El frontend no es autoridad de gasto.
