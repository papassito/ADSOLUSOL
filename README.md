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
- .NET MAUI Blazor (Aplicación de escritorio nativa de Windows)
- UI compartida en una Librería de Clases Razor (RCL)
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
GET    /api/marketing/adsolusol/status
GET    /api/marketing/adsolusol/ping
```

`MarketingController` declara la ruta base `/api/marketing/adsolusol`, pero actualmente no contiene acciones. Esa ruta no debe tratarse como API funcional todavía.

## Autenticación y Tenant

El sistema utiliza un `SignatureVerificationMiddleware` para proteger los endpoints de la API.

- **Estado:** `IMPLEMENTED_AND_WIRED`. El middleware está conectado en `Program.cs`.
- **Mecanismo:** Verificación de firmas Ed25519, timestamp y protección anti-reenvío con nonce.
- **Resolución de Tenant:** El middleware resuelve el `NodeId` a un `TenantId` autorizado y lo inyecta en `HttpContext.Items["TenantId"]`.
- **Rutas Públicas:** La UI de Blazor y el endpoint `/api/health` son accesibles sin firma.

## SQLite

La aplicación de escritorio MAUI crea una base de datos `adsolusol.db` en el directorio de datos de la aplicación del usuario (`AppDataDirectory`) y asegura que el esquema se cree al arrancar. La API web utiliza una cadena de conexión definida en la configuración.


## UI

El proyecto cuenta con dos interfaces de usuario:

### 1. Aplicación de Escritorio (MAUI Blazor)

La interfaz de usuario principal es una aplicación de escritorio nativa de Windows construida con **.NET MAUI Blazor**. Los componentes de la UI residen en el proyecto `src/ADSOLUSOL.Presentation.Shared` y son consumidos por el proyecto de escritorio `src/ADSOLUSOL.Presentation.Desktop`.

### 2. Panel Web (React)

Adicionalmente, existe un panel de administración web desarrollado en React (`src/ADSOLUSOL.Presentation.Web`) que consume la API para visualización y gestión de campañas. Esta interfaz sigue el principio de "Zero Synthetic", mostrando únicamente datos reales devueltos por el backend.

## SIC / Marketing Brain

`HealthController` no intenta consultar `{SolusolAuthV1:SicBaseUrl}/health`. Su única responsabilidad es verificar la salud de la base de datos local.

La integración con **Marketing Brain (SIC) es real y está activa**. El cliente (`MarketingBrainClient`) utiliza `HttpClient` para enviar telemetría de eventos (impresiones, clics) al servicio externo y realiza comprobaciones de disponibilidad de red. Se han eliminado todas las implementaciones ficticias (mocks).

## Regresiones

`tests/ADSOLUSOL.RegressionTests/Program.cs` contiene **17 comprobaciones numeradas de negocio**. La existencia de esas comprobaciones no equivale por sí sola a `17/17 VERIFIED PASS`; ese estado requiere una ejecución reciente con código de salida 0.

## Desarrollo

Para iniciar la aplicación de escritorio en modo de desarrollo con hot-reload, ejecuta:
```powershell
.\Start-Dev.ps1
```
Para construir el ejecutable de producción, usa:
```powershell
.\BUILD-ADSOLUSOL.ps1
```

## Estado antes de release

Pendientes de cierre técnico:
- Aislamiento de tenant completo en todas las superficies (en progreso).
- Integración real o estado `DISCONNECTED` de Marketing Brain/SIC.
- Estrategia de empaquetado y despliegue para la aplicación MAUI (e.g., MSIX).

La documentación de detalle está indexada en [`docs/LIBRARY.md`](docs/LIBRARY.md).
