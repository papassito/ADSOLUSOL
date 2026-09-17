# AD SOLUSOL — Advertising & Growth Engine

**STATUS:** AUTHORITATIVE SPECIFICATION / ACTIVE BASELINE  
**PRODUCT:** AD SOLUSOL (ADS)  
**DOMAIN:** Advertising & Growth  
**PLATFORM:** SOLUSOL Intelligence Center (SIC)  
**COMMERCIAL HEAD:** KLIK Soft PRO  
**SOFTWARE DIRECTION:** solusol.net  
**SUPPORT:** CM Soluciones  


## 1. Definición

**AD SOLUSOL (ADS)** es el motor nativo y soberano de pauta publicitaria, monetización y análisis del rendimiento de anuncios dentro del ecosistema **solusol.net / SIC**.

Su responsabilidad es administrar campañas, placements, creativos, impresiones, clics, CTR, CPM, CPC y consumo presupuestario mediante telemetría first-party y reglas de veracidad estrictas.

## 2. Dentro de ADS

- administración de campañas;
- inventario de placements;
- entrega controlada de creativos;
- registro de impresiones;
- registro de clics;
- validación de eventos;
- cálculo de CTR;
- débito CPM/CPC;
- control de presupuesto;
- telemetría publicitaria;
- publicación de señales hacia Marketing/Growth;
- integración con SIC y ORCHESTA.

## 3. Fuera de ADS

- SEO orgánico;
- SUPER SEO;
- cálculo global de Growth Score;
- WAF/DDoS como dominio primario;
- administración soberana de identidad de Nodes;
- fiscalidad, contabilidad o cumplimiento tributario.

## 4. Frontera con GROWTH

```text
SEO / SUPER SEO ──► Señales orgánicas ┐
VIGILANCIA ───────► Seguridad         │
PERFORMANCE ──────► Rendimiento       ├──► GROWTH
AD SOLUSOL ───────► CTR/CPM/CPC       │
ANALYTICS ────────► Conversión        ┘
```

ADS aporta señales publicitarias. GROWTH consolida el análisis comercial global.

## 5. Zero-Synthetic Advertising Data

```text
DISCONNECTED != 0
NO_DATA != ZERO PERFORMANCE
UNVERIFIED != VERIFIED
UNKNOWN != ZERO SPEND
```

Si una fuente no está disponible, ADS conserva el estado real. No fabrica actividad para completar dashboards.

## 6. API base

```text
GET  /api/marketing/adsolusol
POST /api/marketing/adsolusol/campaigns
POST /api/marketing/adsolusol/campaigns/:id/toggle
POST /api/marketing/adsolusol/campaigns/:id/click
POST /api/marketing/adsolusol/campaigns/:id/impression
```

## 7. Estado observado del código heredado

La evidencia suministrada describe campañas mantenidas en memoria, publicación de eventos ya existente y persistencia SQLite/multi-tenant/filtro antifraude todavía planificados. Esta biblioteca no transforma capacidades planificadas en capacidades implementadas.
