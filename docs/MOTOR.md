# AD SOLUSOL — Motor Publicitario

**Estado:** IMPLEMENTED / PARTIAL

## Flujo actual

```text
Campaign
   ↓
Placement association
   ↓
Eligibility
   ↓
Creative association
   ↓
Serve
   ↓
Impression / Click
   ↓
EventProcessing
   ├──► AdEvent persistence
   ├──► Budget debit
   └──► Metrics by persisted events
```

## Elegibilidad implementada

`AdServingService` obtiene campañas asociadas al placement y el repositorio filtra actualmente por:

- `Status = ACTIVE`;
- `TenantId`;
- presupuesto restante.

El servicio comprueba además rango de fechas.

## Brechas actuales

- `Placement.IsEnabled` no participa explícitamente en la consulta de elegibilidad actual;
- `Creative.IsEnabled` no participa explícitamente en `GetEligibleCreativeForCampaignAsync`;
- la selección de campaña se randomiza con `Guid.NewGuid()`;
- tenant authorization todavía no está resuelto en el pipeline HTTP.

## Persistencia

La implementación actual usa SQLite. No mantiene campañas únicamente en memoria.

EF Core administra el modelo/esquema inicial con `EnsureCreated()`, mientras varios repositorios usan Dapper para operaciones de datos. La estrategia de migraciones/versionado para upgrades de producción sigue pendiente.

## Autoridad

El backend es autoridad para aceptación de evento y débito presupuestario. El navegador no es autoridad financiera.
