# AD SOLUSOL — Campaign

**Estado:** CURRENT DOMAIN SHAPE / requisitos adicionales en `REQUIREMENTS.md`

## Modelo actual

```text
Campaign
├── Id              string (GUID textual)
├── TenantId        string
├── Name            string
├── Status          string
├── Budget          decimal
├── BudgetSpent     decimal
├── RemainingBudget derivado
├── CostPerMille    decimal
├── CostPerClick    decimal
├── StartDateUtc    DateTime
├── EndDateUtc      DateTime
└── CreatedAtUtc    DateTime
```

## Estados

La documentación normativa reconoce:

```text
SCHEDULED
ACTIVE
PAUSED
COMPLETED
```

`CampaignService.CreateAsync` crea actualmente la campaña con estado `PAUSED`.

## Reglas implementadas relevantes

- listado por tenant;
- consulta por id con comprobación de tenant en `CampaignService.GetAsync`;
- actualización de estado con comprobación de tenant;
- serving limitado a campañas `ACTIVE`, vigentes y con presupuesto disponible;
- débito evita `BudgetSpent + Cost > Budget`.

## Brechas

- el endpoint de status no demuestra validación estricta de transición entre estados;
- la resolución/autoridad del tenant HTTP no está conectada;
- anunciante, modelo de pricing separado y placements canónicos del diseño anterior no forman parte de la entidad `Campaign` actual.

Esos elementos pueden permanecer como requisitos/roadmap, pero no como campos de runtime actuales.
