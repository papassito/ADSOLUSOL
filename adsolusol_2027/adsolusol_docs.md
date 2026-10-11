# Documentación Técnica: Motor adsolusol (Producción)

El motor **adsolusol** es el núcleo central de subasta, gestión y telemetría publicitaria. Opera como un servidor Node.js/Express independiente, centralizando toda la lógica de negocio sin depender de servicios externos o nubes costosas.

## Arquitectura de Producción

- **Framework**: Express (Node.js)
- **Persistencia**: JSON Transaccional (Atomic Write/Rename)
- **Seguridad**: Autenticación HMAC vía API Key, Rate Limiting (1000 req/min), CORS restringido.
- **Validación**: Schema Enforcement con Zod.

## API Pública (Para sitios clientes: adsolusol.solusol.net, api.solusol.net)

Toda petición pública requiere el header `X-API-KEY`.

### 1. Solicitar Anuncio
`GET /api/public/ad-request`

- **Header**: `X-API-KEY: <TU_API_KEY>`
- **Respuesta**:
  - `200 OK`: `{ "ad": { ...campaign_data } }`
  - `204 No Content`: No hay campañas activas.
  - `401 Unauthorized`: API Key inválida.

### 2. Telemetría de Eventos
`POST /api/public/telemetry`

- **Header**: `X-API-KEY: <TU_API_KEY>`, `Content-Type: application/json`
- **Body**:
  ```json
  {
    "campaign_id": "string",
    "event_type": "impression" | "click",
    "user_ip": "string",
    "user_agent": "string"
  }
  ```
- **Respuesta**: `200 OK`

---

## Configuración de Seguridad

Para activar la seguridad en producción, debes definir la variable de entorno:
`ADSOLUSOL_API_KEY=tu_clave_secreta_aqui`
