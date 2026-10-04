# AD SOLUSOL — Marketing Brain & Telemetría SIC

**Estado de diseño:** TARGET CAPABILITY  
**Estado runtime actual:** HTTP IMPLEMENTADO / ENTREGA NO GARANTIZADA  
**Modo Operativo:** Decoupled HTTP / Sin Outbox Persistente

## Propósito autorizado

Marketing Brain es una capa de correlación y recomendación que puede consumir señales verificadas de ADS y, cuando existan contratos autorizados, de SEO/SUPER SEO, Analytics, Performance y Vigilancia.

Puede producir recomendaciones sobre presupuesto, rendimiento, placements y campañas. No es fuente autoritativa de clics, impresiones, conversiones ni gasto (`Recommendation != Execution`).

## Modo Operativo y Mapeo de Red

El cliente `MarketingBrainClient` consume el endpoint central de SIC de manera asíncrona y no bloqueante sobre el ciclo de vida del débito y serving:

* **`CONNECTED`:** Telemetría de eventos publicitarios (`Click`, `Impression`) transmitida en tiempo real vía peticiones POST.
* **`DEGRADED / DISCONNECTED`:** Ante latencia elevada o fallo de red, el fallo se absorbe sin interrumpir el serving. Sin embargo, no existe garantía de entrega ni reintento (sin Outbox persistente).

## Invariantes de Seguridad y Negocio

```text
Recommendation != Authorized Mutation
Recommendation != Execution
DISCONNECTED != AVAILABLE
```

Las señales emitidas o recibidas actúan exclusivamente como recomendaciones no vinculantes. Toda mutación de campañas, presupuestos o débitos requiere autorización, política y evidencia independientes en el runtime local del Tenant.
```

Toda automatización futura requiere autorización, política y evidencia independientes.
