# AD SOLUSOL — Marketing Brain & Telemetría SIC

**Estado de diseño:** TARGET CAPABILITY  
**Estado runtime actual:** IMPLEMENTED / ASYNCHRONOUS_RESILIENT  
**Modo Operativo:** Decoupled HTTP / Disconnected Tolerant

## Propósito autorizado

Marketing Brain es una capa de correlación y recomendación que puede consumir señales verificadas de ADS y, cuando existan contratos autorizados, de SEO/SUPER SEO, Analytics, Performance y Vigilancia.

Puede producir recomendaciones sobre presupuesto, rendimiento, placements y campañas. No es fuente autoritativa de clics, impresiones, conversiones ni gasto (`Recommendation != Execution`).

## Modo Operativo y Mapeo de Red

El cliente `MarketingBrainClient` consume el endpoint central de SIC de manera asíncrona y no bloqueante sobre el ciclo de vida del débito y serving:

* **`CONNECTED`:** Telemetría de eventos publicitarios (`Click`, `Impression`) transmitida en tiempo real vía peticiones POST autorizadas.
* **`DEGRADED / DISCONNECTED`:** Ante latencia elevada, timeout o errores de red/5xx, el fallo se absorbe de forma controlada sin comprometer el serving ni la persistencia local. Los eventos y métricas se consolidan localmente en `AdEvent` (SQLite), garantizando consistencia y cero impacto en el rendimiento publicitario local (`NO_DATA != ZERO PERFORMANCE`).

## Invariantes de Seguridad y Negocio

```text
Recommendation != Authorized Mutation
Recommendation != Execution
Authentication != Authorization
```

Las señales emitidas o recibidas actúan exclusivamente como recomendaciones no vinculantes. Toda mutación de campañas, presupuestos o débitos requiere autorización, política y evidencia independientes en el runtime local del Tenant.
```

Toda automatización futura requiere autorización, política y evidencia independientes.
