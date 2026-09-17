# AD SOLUSOL — Contracts

## Contract: AdCampaign

Campos canónicos observados:

```text
id
name
advertiser
status
placementZone
startDate
endDate
budgetTotalUsd
budgetSpentUsd
impressionsCount
clicksCount
ctrPct
targetUrl
bannerAssetUrl?
pricingModel
cpmRateUsd?
cpcRateUsd?
tenant_id   [objetivo contractual; no implementado en el legado observado]
```

Estados:

```text
ACTIVE
PAUSED
SCHEDULED
COMPLETED
```

Pricing:

```text
CPM
CPC
```

## Contract: AdEvent

```text
event_id
event_type
campaign_id
placement
occurred_at
received_at
verification_status
source_context
tenant_id
```

`event_type`:

```text
IMPRESSION
CLICK
```

## Contract: Availability

```text
AVAILABLE
DISCONNECTED
NO_DATA
UNAVAILABLE
UNVERIFIED
UNDETERMINED
```

## Contract: Domain Events

Eventos observados o definidos por la documentación fuente:

```text
CAMPAIGN_LAUNCHED
CAMPAIGN_STATUS_CHANGED
AD_CLICK_VERIFIED
```

Los futuros eventos adicionales deben versionarse y documentarse antes de ser tratados como contrato estable.

## Contract: Money

La representación de interfaz puede usar `number`, pero persistencia/cálculo autoritativo debe preservar precisión decimal.

## Contract: Node Identity Consumption

Cuando una señal provenga de un Node gobernado por CORE, ADS/SIC consume una identidad verificable. Una firma válida prueba procedencia criptográfica, no autorización.
