# AD SOLUSOL — Validate

## Propósito

Validate decide si una campaña, impresión o clic cumple el contrato necesario para producir efectos.

## Validación de campaña

- identidad;
- anunciante;
- fechas;
- status;
- placement;
- pricing model;
- tarifa requerida;
- presupuesto;
- target URL;
- creativo;
- tenant cuando aplique.

## Validación de evento

```text
Event received
   ↓
Schema
   ↓
Campaign exists
   ↓
Campaign eligible
   ↓
Placement matches
   ↓
Duplicate / Replay check
   ↓
Traffic verification
   ↓
ACCEPTED / REJECTED / DUPLICATE / UNVERIFIED
```

## Regla financiera

Solo `ACCEPTED` puede producir incremento facturable y débito.

## Estado heredado

La documentación suministrada indica que el filtro de fraude de clics y las firmas de agente están planificados/no implementados. No se declaran como capacidades existentes.
