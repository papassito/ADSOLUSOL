# AD SOLUSOL — Marketing API

**Estado del Documento:** Actualizado contra el runtime del commit `9f95b05`. La información anterior era obsoleta.

## Arquitectura de API

La API actual está construida con ASP.NET Core 8 y utiliza el patrón de `Controllers`. Las rutas base de los recursos principales son:
- `/api/Campaigns`
- `/api/Placements`
- `/api/Creatives`
- `/api/Assignments`
- `/api/Serve`

## Health

```text
GET /health
```

La API C# comprueba SQLite y la integración SIC en /api/health. SQLite tiene almacenamiento real; SIC sigue no disponible. /api/health/storage informa solo el almacenamiento. Las respuestas HTTP se verificaron mediante una prueba con reinicio del proceso.

## Implementación C# actual

La API local implementa todos los endpoints de la sección `ADS` de este contrato.
- `GET /campaigns` y `POST /campaigns` están operativos.
- `POST /campaigns/{id}/toggle`, `POST /campaigns/{id}/click` y `POST /campaigns/{id}/impression` están implementados y funcionales.
- El tenant es fijado por configuración del servidor (`Api__TenantId`).
- La cabecera `X-Api-Key` protege las operaciones locales. La autenticación final con identidad SIC (Ed25519) también está implementada.
- `POST /campaigns/{id}/content` es el único endpoint que devuelve indisponibilidad (`503`) de forma intencionada, a la espera de la integración con el servicio de contenido de SIC.
