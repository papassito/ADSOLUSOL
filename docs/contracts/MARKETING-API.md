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

## Implementación C# actual

La API local implementa todos los endpoints de la sección `ADS` de este contrato.
- `GET /campaigns` y `POST /campaigns` están operativos.
- `POST /campaigns/{id}/toggle`, `POST /campaigns/{id}/click` y `POST /campaigns/{id}/impression` están implementados y funcionales.
- El tenant es fijado por configuración del servidor (`Api__TenantId`).
- La cabecera `X-Api-Key` protege las operaciones locales. La autenticación final con identidad SIC (Ed25519) también está implementada.
- `POST /campaigns/{id}/content` es el único endpoint que devuelve indisponibilidad (`503`) de forma intencionada, a la espera de la integración con el servicio de contenido de SIC.
