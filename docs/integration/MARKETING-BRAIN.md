# AD SOLUSOL — Marketing Brain

**Estado de diseño:** TARGET CAPABILITY  
**Estado runtime actual:** HTTP IMPLEMENTADO / ENTREGA NO GARANTIZADA / CONECTIVIDAD NO VERIFICADA

## Propósito autorizado

Marketing Brain es una capa de correlación y recomendación que puede consumir señales verificadas de ADS y, cuando existan contratos autorizados, de SEO/SUPER SEO, Analytics, Performance y Vigilancia.

Puede producir recomendaciones sobre presupuesto, rendimiento, placements y campañas. No es fuente autoritativa de clics, impresiones, conversiones ni gasto.

## Estado del código actual

`MarketingBrainClient` implementa `IMarketingBrainService` utilizando `HttpClient` real hacia el endpoint configurado de SIC.

**Brecha real (P0):** Ante caídas de red o timeouts en `EmitTelemetryAsync`, los errores son absorbidos sin reintentos garantizados ni cola Outbox persistente. La entrega de telemetría publicitaria hacia SIC no está garantizada hasta implementar buffer y resiliencia activa.

Conectividad con backend SIC externo permanece sin verificar en tests de integración en vivo (`DISCONNECTED != ZERO ACTIVITY`).

## Invariante

```text
Recommendation != Authorized Mutation
```

Toda automatización futura requiere autorización, política y evidencia independientes.
