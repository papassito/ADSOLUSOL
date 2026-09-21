# AD SOLUSOL — Advertising & Growth Engine

**Estado documental:** PRE-SELLO / alineado al código del ZIP de revisión 2026-09-18  
**Estado de release:** NOT RELEASE-CERTIFIED  
**Producto:** AD SOLUSOL (ADS)  
**Cabeza comercial:** KLIK Soft PRO  
**Dirección de software:** solusol.net  
**Soporte:** CM Soluciones

## Propósito

AD SOLUSOL es el motor de publicidad, monetización y analítica publicitaria del ecosistema solusol.net. Su dominio cubre campañas, placements, creativos, serving, impresiones, clics, métricas y presupuesto.

ADS mantiene separación estricta respecto de SEO/SUPER SEO, CORE, ORCHESTA y SIC. Puede integrarse con esos módulos mediante contratos explícitos, pero no absorbe sus responsabilidades.

## Principios

- **Zero-Synthetic:** no inventar clics, impresiones, gasto, disponibilidad ni telemetría.
- **Servidor autoritativo:** gasto y eventos aceptados se determinan en backend.
- **Authentication != Authorization:** una firma válida no equivale a permiso.
- **Tenant isolation:** toda operación multi-tenant debe resolver y aplicar un tenant autorizado.
- **Recommendation != Execution:** una recomendación de inteligencia no ejecuta mutaciones por sí sola.

## Stack observado

- .NET 8 / ASP.NET Core
- React 18 + TypeScript + Vite
- SQLite
- EF Core para contexto/esquema y Dapper en repositorios específicos

## API implementada actualmente

Las rutas observadas en los controllers actuales son:

```text
GET    /api/Campaigns
GET    /api/Campaigns/{id}
POST   /api/Campaigns
POST   /api/Campaigns/{id}/status
GET    /api/Campaigns/{id}/metrics
POST   /api/Campaigns/{id}/click
POST   /api/Campaigns/{id}/impression

POST   /api/Placements
POST   /api/Creatives

POST   /api/assignments/placement
POST   /api/assignments/creative

GET    /api/Serve?placementCode={code}
GET    /api/health
```

`MarketingController` declara la ruta base `/api/marketing/adsolusol`, pero actualmente no contiene acciones. Esa ruta no debe tratarse como API funcional todavía.

## Autenticación y tenant

Existen `CoreSignatureVerifier` y `SignatureVerificationMiddleware` con verificación Ed25519, timestamp y nonce anti-replay. Ambas están completamente integradas:

- `Program.cs` conecta el `SignatureVerificationMiddleware` en el pipeline de ejecución HTTP.
- El middleware realiza la verificación Ed25519 y resuelve dinámicamente la correspondencia del `NodeId` de origen con el `TenantId` autorizado, inyectándolo en `HttpContext.Items["TenantId"]`.
- `CampaignsController` y `ServeController` consumen correctamente el tenant validado.

No existe protección por `X-Api-Key` activa, priorizando la solidez de la firma criptográfica Ed25519.

## SQLite

En Development existe:

```text
ConnectionStrings:DefaultConnection = Data Source=App_Data/adsolusol.db
```

`Program.cs` crea `App_Data` bajo `ContentRootPath` y usa `EnsureCreated()`.

En `appsettings.json` de Production **no existe todavía** `ConnectionStrings:DefaultConnection`. La ubicación final de datos de producción, la migración/versionado de esquema y `ProgramData` siguen pendientes del cierre de release.

## UI

La UI existe en:

```text
src/ADSOLUSOL.Presentation.Web
```

`api.ts` usa las rutas reales `/api/...` y soporta base same-origin. El proxy de Vite apunta a `http://127.0.0.1:5000` durante desarrollo, pero eso no demuestra un binding por defecto de ASP.NET.

La UI todavía no debe describirse como integrada a `wwwroot` ni empaquetada en `dotnet publish` mientras `Program.cs` y el `.csproj` no demuestren esa integración.

## SIC / Marketing Brain

`HealthController` intenta consultar `{SolusolAuthV1:SicBaseUrl}/health` y devuelve `Healthy` o `Degraded` según SQLite y SIC.

`MarketingBrainClient` se ha re-implementado para establecer conexiones HTTP asíncronas reales a la base de URLs configuradas, emitiendo telemetría JSON y verificando el pulso (Heartbeat) de disponibilidad del SIC en runtime en lugar de utilizar respuestas estáticas ficticias.

## Regresiones

`tests/ADSOLUSOL.RegressionTests/Program.cs` contiene **17 comprobaciones numeradas de negocio**. La existencia de esas comprobaciones no equivale por sí sola a `17/17 VERIFIED PASS`; ese estado requiere una ejecución reciente con código de salida 0.

## Desarrollo

```powershell
dotnet build ADSOLUSOL.sln

dotnet run --project tests/ADSOLUSOL.RegressionTests/ADSOLUSOL.RegressionTests.csproj

.\Start-Dev.ps1
```

El puerto de desarrollo de ASP.NET no debe documentarse como fijo hasta que exista binding explícito. Vite actualmente espera la API en `127.0.0.1:5000` mediante proxy de desarrollo.

## Estado antes de release

Pendientes de cierre técnico, entre otros:

- UI de producción servida por ASP.NET / `wwwroot`;
- configuración SQLite de Production y ruta de datos instalada;
- estrategia segura de actualización de esquema;
- wiring de autenticación;
- resolución NodeId/identidad autorizada a TenantId;
- aislamiento tenant completo en todas las superficies;
- integración real o estado `DISCONNECTED` de Marketing Brain/SIC;
- `dotnet publish` reproducible;
- instalador y smoke test en máquina limpia.

La documentación de detalle está indexada en [`docs/LIBRARY.md`](docs/LIBRARY.md).
