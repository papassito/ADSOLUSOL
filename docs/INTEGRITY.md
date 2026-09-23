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

Verificado en suite de regresión con protección contra ráfagas de eventos duplicados (Test [19]): el índice único y la verificación atómica garantizan que los eventos repetidos se clasifican como Duplicate sin doble débito.

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

`CoreSignatureVerifier` implementa firma, ventana temporal y nonce. El pipeline se ha completado integrando `SignatureVerificationMiddleware` en `Program.cs`, lo que permite validar firmas criptográficas Ed25519 e inyectar el `TenantId` autorizado en `HttpContext.Items`.

## Marketing Brain / SIC

`MarketingBrainClient` se conecta mediante `HttpClient` para comunicarse con las APIs del backend de Marketing Brain y SIC, validando disponibilidad a través de transacciones reales e inyectando de forma asíncrona la telemetría de eventos.
