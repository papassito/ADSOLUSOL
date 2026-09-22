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
| Signature Middleware | CONNECTED | Conectado activamente mediante `app.UseMiddleware<SignatureVerificationMiddleware>()` |
| Tenant Resolver / Auth | IMPLEMENTED | Resolución autorizada e inyectada en `HttpContext.Items["TenantId"]` |
| Marketing Brain Client | IMPLEMENTED | `MarketingBrainClient` con llamadas HTTP reales e inyección de HttpClient |
| MAUI Blazor UI | IMPLEMENTED | `ADSOLUSOL.Presentation.Desktop` y `ADSOLUSOL.Presentation.Shared` |
| React/Vite UI | IMPLEMENTED SOURCE / NOT PACKAGED | `ADSOLUSOL.Presentation.Web` |
| Health Check | IMPLEMENTED | `GET /api/health` |

## Componentes incompletos o no verificados

| Componente | Estado observado |
|---|---|
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
