# AD SOLUSOL — Campaign

## Modelo canónico

```text
AdCampaign
├── id
├── name
├── advertiser
├── status
├── placementZone
├── startDate
├── endDate
├── budgetTotalUsd
├── budgetSpentUsd
├── impressionsCount
├── clicksCount
├── ctrPct
├── targetUrl
├── bannerAssetUrl?
├── pricingModel
├── cpmRateUsd?
├── cpcRateUsd?
└── tenant_id [objetivo contractual]
```

## Estados

```text
SCHEDULED ──► ACTIVE ◄──► PAUSED
                 │
                 ▼
             COMPLETED
```

## Placements iniciales observados

```text
HEADER_LEADERBOARD
SIDEBAR_RECTANGLE
IN_CONTENT_NATIVE
STICKY_FOOTER
```

## Reglas

- `endDate >= startDate`;
- CPM requiere tarifa CPM;
- CPC requiere tarifa CPC;
- una campaña terminada no entrega anuncios;
- cambios de tarifa deben ser trazables;
- el gasto no lo fija el cliente;
- una campaña no debe cruzar tenants.

## Datos heredados

La documentación fuente reporta tres campañas estáticas iniciales en memoria. Se consideran fixtures/estado legado, no requisito de negocio permanente.
