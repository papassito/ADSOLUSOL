# AD SOLUSOL — Marketing API

**Estado:** CURRENT IMPLEMENTATION CONTRACT / PRE-SELLO  
**Fuente:** controllers y pipeline presentes en el ZIP de revisión 2026-09-18

## Rutas activas observadas

### CampaignsController

```text
POST   /api/Campaigns
GET    /api/Campaigns
GET    /api/Campaigns/{id}
POST   /api/Campaigns/{id}/status
GET    /api/Campaigns/{id}/metrics
POST   /api/Campaigns/{id}/click
POST   /api/Campaigns/{id}/impression
```

### PlacementsController

```text
POST   /api/Placements
```

### CreativesController

```text
POST   /api/Creatives
```

### AssignmentsController

```text
POST   /api/assignments/placement
POST   /api/assignments/creative
```

Body actual:

```json
{
  "campaignId": "string",
  "entityId": 1
}
```

### ServeController

```text
GET /api/Serve?placementCode={code}
```

Si no existe anuncio elegible, responde `404` con un mensaje de ausencia de anuncios elegibles.

### HealthController

```text
GET /api/health
```

El endpoint comprueba apertura de SQLite y consulta `{SolusolAuthV1:SicBaseUrl}/health`. Devuelve HTTP 200 con `Status = Healthy` o `Degraded` y checks `Database` / `SicEngine`.

## Ruta reservada sin acciones activas

`MarketingController` declara:

```text
/api/marketing/adsolusol
```

pero actualmente no define acciones. No debe documentarse como API funcional.

## Autenticación

`CoreSignatureVerifier` y `SignatureVerificationMiddleware` existen. El middleware espera:

```text
X-Solusol-Signature
X-Solusol-Node-Id
X-Solusol-Timestamp
X-Solusol-Nonce
```

Sin embargo, `Program.cs` no ejecuta `UseMiddleware<SignatureVerificationMiddleware>()`. Estado actual:

```text
ED25519 VERIFIER = IMPLEMENTED COMPONENT
SIGNATURE MIDDLEWARE = IMPLEMENTED_BUT_NOT_WIRED
```

No existe protección `X-Api-Key` activa en el pipeline actual.

## Tenant y autorización

`CampaignsController` y `ServeController` leen:

```text
HttpContext.Items["TenantId"]
```

El middleware de firma actual no asigna ese valor y no existe un resolver NodeId→TenantId conectado. Por tanto:

```text
TENANT RESOLUTION = NOT_IMPLEMENTED IN CURRENT PIPELINE
AUTHENTICATION != AUTHORIZATION
```

El aislamiento tenant no debe considerarse cerrado. La consulta/listado/actualización de campañas y serving contienen filtros de tenant en parte del flujo, pero métricas, asociaciones, placements y creatives no tienen una garantía integral de tenant en sus superficies actuales.

## Idempotencia y eventos

`AdEvent.EventId` tiene índice único. `EventProcessingService` comprueba duplicidad antes de procesar y realiza evento + débito dentro de una transacción. Esto no sustituye una prueba de concurrencia del runtime final.

## Estado de SIC / Marketing Brain

`HealthController` sí intenta consultar SIC. En cambio, `MarketingBrainClient` actual no verifica una dependencia externa: devuelve `true` en `PingAsync`/`IsAvailableAsync` y `EmitTelemetryAsync` no realiza I/O.

Por Zero-Synthetic:

```text
MARKETING BRAIN CONNECTIVITY = UNVERIFIED / NOT IMPLEMENTED
```

## Rutas históricas que NO representan el runtime actual

No usar como implementación actual:

```text
/api/marketing/adsolusol/campaigns
/api/marketing/adsolusol/campaigns/{id}/toggle
/api/marketing/adsolusol/campaigns/{id}/content
/health
/api/Serve/ad
```
