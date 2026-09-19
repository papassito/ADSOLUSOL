# AD SOLUSOL — Validate

**Estado:** IMPLEMENTED / PARTIAL

## Validaciones observadas actualmente

### Campaign

- creación con `TenantId` recibido por el servicio;
- `GetAsync` y `UpdateStatusAsync` comparan `TenantId`;
- estado inicial de creación: `PAUSED`;
- fechas por defecto si no se proporcionan.

La implementación actual no demuestra todavía una máquina de estados estricta que impida cualquier transición arbitraria enviada al endpoint `/status`.

### Serving

- placement existente;
- campaña `ACTIVE`;
- tenant coincidente en consulta de campañas elegibles;
- presupuesto restante;
- rango de fechas;
- existencia de creative asociado.

### Events

`EventProcessingService` valida actualmente:

- `EventId` no procesado previamente;
- campaña existente;
- campaña `ACTIVE`;
- presupuesto restante;
- tipo de evento parseable (`Click` / `Impression`);
- débito presupuestario exitoso dentro de transacción.

## Validaciones todavía no cerradas

No hay evidencia en el flujo actual de validación integral de:

- correspondencia campaign↔creative↔placement al registrar cada evento;
- `Placement.IsEnabled` durante serving;
- `Creative.IsEnabled` durante serving;
- autorización tenant completa en todos los endpoints;
- rate limiting;
- validación de `TargetUrl`/`ContentUrl` contra políticas de seguridad;
- antifraude de tráfico.

No se deben documentar esas capacidades como implementadas hasta disponer de código y pruebas.
