# AD SOLUSOL — Marketing Brain

**Estado de diseño:** TARGET CAPABILITY  
**Estado runtime actual:** NOT_IMPLEMENTED / UNVERIFIED

## Propósito autorizado

Marketing Brain es una capa de correlación y recomendación que puede consumir señales verificadas de ADS y, cuando existan contratos autorizados, de SEO/SUPER SEO, Analytics, Performance y Vigilancia.

Puede producir recomendaciones sobre presupuesto, rendimiento, placements y campañas. No es fuente autoritativa de clics, impresiones, conversiones ni gasto.

## Estado del código actual

`MarketingBrainClient` implementa `IMarketingBrainService`, pero actualmente:

```text
PingAsync()        => true
IsAvailableAsync() => true
EmitTelemetryAsync => no-op
```

No existe I/O que demuestre conexión con SIC o con un Marketing Brain real. Estos retornos no deben presentarse como disponibilidad verificada.

## Invariante

```text
Recommendation != Authorized Mutation
```

Toda automatización futura requiere autorización, política y evidencia independientes.
