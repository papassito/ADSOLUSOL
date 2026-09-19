# AD SOLUSOL — Advertising & Growth Engine

**STATUS:** AUTHORITATIVE PRODUCT SCOPE / IMPLEMENTATION PARTIAL  
**PRODUCT:** AD SOLUSOL (ADS)  
**DOMAIN:** Advertising & Growth  
**COMMERCIAL HEAD:** KLIK Soft PRO  
**SOFTWARE DIRECTION:** solusol.net  
**SUPPORT:** CM Soluciones

## 1. Definición

AD SOLUSOL es el motor de pauta publicitaria, monetización y análisis del rendimiento publicitario del ecosistema solusol.net.

Su responsabilidad abarca campañas, placements, creativos, serving, impresiones, clics, métricas de publicidad y control de presupuesto.

## 2. Dentro de ADS

- campañas;
- placements;
- creativos;
- asociaciones campaña/placement y campaña/creativo;
- selección de anuncios elegibles;
- registro idempotente de eventos;
- impresiones y clics;
- métricas;
- CPM/CPC;
- presupuesto;
- telemetría publicitaria cuando exista una integración real.

## 3. Fuera de ADS

- SEO/SUPER SEO como motor primario;
- identidad/autorización soberana de CORE;
- coordinación transversal propia de ORCHESTA;
- disponibilidad/monitorización global propia de SIC;
- fiscalidad, contabilidad y cumplimiento tributario.

## 4. Flujo de negocio objetivo

```text
CAMPAIGN
   ↓
PLACEMENT
   ↓
CREATIVE
   ↓
SERVING
   ↓
IMPRESSION / CLICK
   ↓
METRICS
   ↓
BUDGET
```

## 5. Zero-Synthetic Advertising Data

```text
DISCONNECTED != AVAILABLE
NO_DATA != ZERO PERFORMANCE
UNVERIFIED != VERIFIED
UNKNOWN != ZERO SPEND
```

## 6. API implementada observada

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

`/api/marketing/adsolusol` existe únicamente como ruta base de un controller sin acciones; no se considera endpoint operativo.

## 7. Estado de implementación

### Implementado

- persistencia SQLite para campañas, placements, creativos, asociaciones y eventos;
- creación/listado/consulta/estado de campañas;
- creación de placements y creativos;
- asociaciones;
- serving por placement y tenant;
- eventos click/impression con idempotencia por `EventId`;
- débito condicional de presupuesto;
- métricas básicas;
- health de SQLite y SIC;
- componentes Ed25519 de verificación.

### Parcial o pendiente

- wiring del middleware de firmas en `Program.cs`;
- resolución autorizada de `TenantId`;
- aislamiento tenant completo en métricas/asignaciones/recursos no tenant-scoped;
- filtro explícito `IsEnabled` en serving de placement/creative;
- integración real de Marketing Brain/SIC;
- configuración Production de SQLite;
- migraciones/versionado de esquema;
- integración UI production con ASP.NET publish;
- instalador.

## 8. Regla de autoridad documental

Los documentos de requisitos y arquitectura pueden describir el objetivo autorizado. Las afirmaciones de estado actual deben derivarse del código y de evidencia de ejecución reciente; un diseño no se convierte en implementación por estar documentado.
