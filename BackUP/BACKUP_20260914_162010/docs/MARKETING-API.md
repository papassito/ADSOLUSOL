# AD SOLUSOL — Marketing API

## Base

```text
/api
```

## SEO

```text
GET /api/marketing/seo
```

Responsabilidad: reporte técnico de SEO para dominio objetivo.

## ADS

```text
GET  /api/marketing/adsolusol
POST /api/marketing/adsolusol/campaigns
POST /api/marketing/adsolusol/campaigns/:id/toggle
POST /api/marketing/adsolusol/campaigns/:id/click
POST /api/marketing/adsolusol/campaigns/:id/impression
```

## Eventos asociados observados

```text
CAMPAIGN_LAUNCHED
CAMPAIGN_STATUS_CHANGED
AD_CLICK_VERIFIED
```

## Estado de seguridad observado

La especificación fuente reporta:

- autenticación de rutas Express: planificada/no implementada;
- aislamiento tenant: no verificado;
- crawler SEO: riesgo SSRF pendiente.

Por tanto, esos endpoints no deben describirse como endurecidos hasta existir evidencia.

## Health

```text
GET /api/health
```

Está especificado como contrato de liveness, pero la documentación fuente lo marca planificado/no implementado.

## Wails IPC

La documentación fuente define bindings planificados para `GetSeoReport`, `GetAdSolusolReport` y `CreateCampaign`; no se consideran activos hasta existir evidencia de binding real.
