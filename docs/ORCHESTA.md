# AD SOLUSOL — ORCHESTA Integration

## Rol

ORCHESTA coordina eventos y acciones entre módulos del ecosistema. No es autoridad de cálculo de CTR, CPM, CPC ni presupuesto ADS.

## Eventos mínimos observados

```text
CAMPAIGN_LAUNCHED
CAMPAIGN_STATUS_CHANGED
AD_CLICK_VERIFIED
```

## Flujo

```text
AD SOLUSOL
   ↓
Domain Event
   ↓
ORCHESTA
   ├──► SIC
   ├──► Marketing Brain
   └──► Otros consumidores autorizados
```

## Seguridad

Si un evento está ligado a identidad de Node:

1. la procedencia criptográfica se verifica conforme al contrato de CORE;
2. una firma válida no concede autorización;
3. anti-replay se evalúa antes de aceptar efectos mutables;
4. ORCHESTA no inventa eventos para compensar desconexiones.

## Desacoplamiento

La caída de ORCHESTA no autoriza a ADS a simular entrega, clics, impresiones ni gasto.
