# AD SOLUSOL — Integrity

**Estado:** NORMATIVE BASELINE + current gaps

## Zero-Synthetic Advertising Data

Prohibido inventar impresiones, clics, conversiones, gasto, disponibilidad o conectividad.

```text
DISCONNECTED != AVAILABLE
DISCONNECTED != 0 ACTIVITY
NO_DATA != ZERO PERFORMANCE
UNVERIFIED != VERIFIED
```

## Idempotencia

Un evento lógico aceptado debe producir como máximo un registro y el débito aplicable. `AdEvent.EventId` tiene índice único y el servicio comprueba existencia antes de procesar.

La resistencia frente a carreras concurrentes debe confirmarse mediante prueba específica; la comprobación previa y el índice único no autorizan a declarar el caso cerrado sin evidencia.

## Presupuesto

```text
Impression cost = CostPerMille / 1000
Click cost      = CostPerClick
```

`UpdateBudgetAsync` condiciona el update a que el gasto resultante no supere el presupuesto.

## CTR

Baseline:

```text
CTR solo es significativo con impresiones verificables.
```

**Brecha actual:** `MetricsService` devuelve `0.0` cuando `impressions == 0`. Eso no satisface todavía la semántica estricta `NO_DATA != ZERO PERFORMANCE` si la UI interpreta ese 0 como rendimiento observado.

## Procedencia y autorización

```text
Valid Signature != Authorization
Authentication != Authorization
NodeId != TenantId
```

`CoreSignatureVerifier` implementa firma, ventana temporal y nonce. El pipeline actual no conecta el middleware ni resuelve tenant.

## Marketing Brain / SIC

Un método que devuelve `true` sin consultar una dependencia externa no constituye evidencia de disponibilidad. `MarketingBrainClient` actual debe considerarse `UNVERIFIED / NOT_IMPLEMENTED` como integración real.
