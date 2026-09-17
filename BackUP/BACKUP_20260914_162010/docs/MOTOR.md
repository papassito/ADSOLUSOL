# AD SOLUSOL — Motor Publicitario

## Responsabilidad

El motor ADS gobierna la ejecución publicitaria desde elegibilidad hasta contabilización.

```text
Campaign
   ↓
Eligibility
   ↓
Placement
   ↓
Delivery
   ↓
Event
   ↓
Validate
   ├──► Metrics
   └──► Budget
```

## Elegibilidad

Una campaña es candidata cuando:

- su estado permite entrega;
- se encuentra dentro de vigencia;
- el placement es compatible;
- el creativo es válido;
- el presupuesto permite continuar;
- el tenant/contexto aplicable coincide.

## Autoridad

El servidor es autoridad para:

- aceptar/rechazar eventos;
- incrementar contadores;
- calcular CTR;
- debitar CPM/CPC;
- cerrar una campaña por límites operativos.

El navegador no es autoridad financiera.

## Persistencia

El código heredado descrito mantiene campañas en memoria. La persistencia durable es una capacidad posterior y debe conservar las mismas invariantes.
