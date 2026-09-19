# AD SOLUSOL — Roadmap

**Estado:** ROADMAP / TARGET. Este documento no describe por sí solo capacidades implementadas.

**PRODUCT:** AD SOLUSOL (ADS)  
**DOMAIN:** Advertising & Growth  
**PLATFORM:** SOLUSOL Intelligence Center (SIC)  
**COMMERCIAL HEAD:** KLIK Soft PRO  
**SOFTWARE DIRECTION:** solusol.net  
**SUPPORT:** CM Soluciones  

## Fase 0 — Baseline documental

- Consolidar identidad y frontera de AD SOLUSOL.
- Consolidar REQUIREMENTS, COMPONENTS, MAP, SITEMAP, CONTRACTS e INTEGRITY.
- Separar definitivamente ADS de dominios fiscales o ajenos.
- Registrar estado real de las capacidades heredadas sin convertir planes en implementación.

## Fase 1 — Campaign Core

- Consolidar `AdCampaign`.
- Definir ciclo de vida `SCHEDULED / ACTIVE / PAUSED / COMPLETED`.
- Definir advertiser, placement, vigencia, presupuesto y pricing.
- Incorporar `tenant_id` al contrato objetivo.
- Validar transiciones de estado.

## Fase 2 — Persistence

- Migrar campañas volátiles en memoria a persistencia durable.
- Preservar precisión monetaria.
- Preservar `NULL` cuando un dato no exista.
- Incorporar aislamiento por tenant.
- Incorporar historial de cambios de campaña.

## Fase 3 — Placement & Creative Delivery

- Consolidar Placement Registry.
- Validar `HEADER_LEADERBOARD`, `SIDEBAR_RECTANGLE`, `IN_CONTENT_NATIVE` y `STICKY_FOOTER`.
- Validar assets y destinos.
- Aplicar CSP.
- Impedir ejecución arbitraria de scripts publicitarios.

## Fase 4 — Event Collection

- Formalizar `IMPRESSION`.
- Formalizar `CLICK`.
- Incorporar `event_id`.
- Incorporar idempotencia.
- Incorporar anti-replay.
- Impedir doble contabilización.

## Fase 5 — Validate Engine

- Validar campaña.
- Validar placement.
- Validar vigencia.
- Validar presupuesto.
- Validar evento.
- Validar duplicados.
- Incorporar controles de tráfico/fraude verificables.
- Distinguir `ACCEPTED`, `REJECTED`, `DUPLICATE`, `UNVERIFIED`.

## Fase 6 — Metrics Engine

- Calcular impresiones verificadas.
- Calcular clics verificados.
- Calcular CTR.
- Preservar `NO_DATA` cuando no exista denominador verificable.
- Separar métricas publicitarias de telemetría operacional.

## Fase 7 — Budget Engine

- Implementar débito CPM.
- Implementar débito CPC.
- Hacer atómico el registro de evento y gasto.
- Evitar sobreconsumo por concurrencia.
- Crear ledger auditable de presupuesto.

## Fase 8 — Integrity

- Aplicar Zero-Synthetic Advertising Data.
- Verificar idempotencia.
- Verificar precisión monetaria.
- Verificar trazabilidad evento → métrica → débito.
- Eliminar cualquier métrica simulada presentada como real.

## Fase 9 — Marketing API

- Evaluar una ruta canónica futura para Marketing/ADS únicamente después de estabilizar y versionar la API actual `/api/*`.
- Consolidar creación de campañas.
- Consolidar toggle.
- Consolidar click.
- Consolidar impression.
- Incorporar autenticación y autorización.
- Incorporar rate limiting.
- Incorporar aislamiento multi-tenant.
- Consolidar `/api/health`.

## Fase 10 — SEO / SUPER SEO Boundary

- Mantener SEO separado de ADS.
- Corregir controles Anti-SSRF del crawler.
- Validar DNS, IPv4, IPv6 y redirecciones.
- Eliminar métricas Core Web Vitals sintéticas.
- Mantener SUPER SEO como correlador hacia GROWTH.

## Fase 11 — Marketing Brain

- Correlacionar ADS, SEO/SUPER SEO, ANALYTICS, PERFORMANCE y VIGILANCIA.
- Generar recomendaciones comerciales.
- Separar observación, inferencia y recomendación.
- No convertir recomendaciones en mutaciones automáticas.

## Fase 12 — AI

- Incorporar capacidades AI desacopladas de proveedor.
- Etiquetar claramente inferencias y recomendaciones.
- Prohibir datos sintéticos presentados como observaciones.
- Mantener autorización humana/política para acciones mutables.

## Fase 13 — AI AD

- Generar propuestas de copy.
- Generar propuestas de CTA.
- Sugerir placements.
- Analizar CTR/CPM/CPC.
- Detectar anomalías.
- Sugerir optimización de presupuesto.
- Mantener `AI Recommendation != Authorized Mutation`.

## Fase 14 — ORCHESTA / SIC

- Publicar eventos de campaña.
- Publicar eventos publicitarios.
- Integrar con ORCHESTA.
- Integrar con SIC.
- Preservar autoridad de ADS sobre métricas y presupuesto.
- Preservar autoridad de CORE sobre identidad y autorización de Nodes.

## Fase 15 — Edge / Cloudflare

- Integrar reverse proxy cuando corresponda.
- Definir bypass de caché para endpoints dinámicos.
- Configurar IP real únicamente desde proxies confiables.
- Mantener WAF/CDN fuera de la semántica del dominio ADS.

## Fase 16 — UI / Dashboard

- Dashboard de campañas.
- Placements.
- Creativos.
- CTR.
- CPM.
- CPC.
- Presupuesto.
- Eventos.
- Estado de disponibilidad.
- Integración con Marketing Brain y AI AD.

## Fase 17 — Pruebas E2E

- Evento duplicado.
- Clic verificado.
- Impresión verificada.
- CPM.
- CPC.
- CTR sin denominador.
- Presupuesto concurrente.
- Tenant isolation.
- CSP/XSS.
- Rate limiting.
- API auth.
- Health.
- ORCHESTA.
- SIC.

## Fase 18 — Release & Rollback

- Validar build.
- Validar migraciones.
- Staging.
- Hash de artefactos.
- Despliegue atómico cuando aplique.
- Rollback verificable.
- Smoke tests posteriores al despliegue.

## Fase 19 — Certificación

- Compilar.
- Ejecutar pruebas.
- Corregir errores reales.
- Repetir hasta obtener baseline verificable.
- No declarar implementación o certificación sin evidencia.

## Regla operativa

```text
BUILD
  ↓
REAL ERROR
  ↓
CORRECT
  ↓
BUILD AGAIN
  ↓
TEST
```

El compilador, las pruebas y la evidencia prevalecen sobre afirmaciones documentales.
