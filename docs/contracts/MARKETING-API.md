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

La API C# comprueba SQLite y la integración SIC en /api/health. SQLite tiene almacenamiento real; SIC sigue no disponible. /api/health/storage informa solo el almacenamiento. Las respuestas HTTP se verificaron mediante una prueba con reinicio del proceso.

## Wails IPC

La documentación fuente define bindings planificados para `GetSeoReport`, `GetAdSolusolReport` y `CreateCampaign`; no se consideran activos hasta existir evidencia de binding real.


## Implementación C# actual

La API local implementa GET y POST /api/marketing/adsolusol/campaigns y GET /api/marketing/adsolusol/campaigns/{id}. El POST recibe name y budget. El tenant es fijado por configuración del servidor. La cabecera X-Api-Key protege las operaciones locales; la identidad SIC está pendiente. POST /api/marketing/adsolusol/campaigns/{id}/content indica indisponibilidad hasta disponer del contrato SIC. Los demás endpoints de esta especificación permanecen planificados.

