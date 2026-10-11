# ADSOLUSOL 2027 — Especificación de API Canónica

**Base URL Canónica:** `https://api.solusol.net/api`  
**Base URL Desarrollo Local:** `http://localhost:5000/api`  
**Portal y Dashboard:** `https://adsolusol.solusol.net`  
**Formato:** JSON (UTF-8 estricto)  

---

## 1. Rutas Públicas y de Diagnóstico

### `GET /api/health`
Comprueba la salud del motor local y las dependencias externas autorizadas.
- **Respuesta `200 OK`:**
```json
{
  "status": "UP",
  "timestamp": "2026-10-10T12:00:00Z",
  "checks": {
    "database": "UP",
    "sicEngine": "UP"
  }
}
```

### `GET /api/Serve?placementCode={code}`
Entrega un creativo elegible para el código de espacio solicitado.
- **Parámetros:** `placementCode` (string, ej. `HEADER_LEADERBOARD`).
- **Respuesta `200 OK`:**
```json
{
  "campaignId": 101,
  "creativeId": 402,
  "title": "Campaña Soberana",
  "imageUrl": "https://assets.solusol.net/creatives/c402.webp",
  "targetUrl": "https://anunciante.com/promocion",
  "pricingModel": "CPM",
  "servedAt": "2026-10-10T12:00:05Z"
}
```
- **Respuesta `404 Not Found`:** No hay anuncios activos o con saldo disponible para ese placement.

---

## 2. Ingesta de Telemetría (First-Party Events)

### `POST /api/Campaigns/{id}/impression`
Registra una impresión verificada y liquida el débito fraccionario CPM si corresponde.
```json
{
  "eventId": "e9b21f3a-7a54-4c28-9842-8c430e38a201",
  "placementId": 1,
  "creativeId": 402,
  "timestamp": "2026-10-10T12:00:06Z"
}
```

### `POST /api/Campaigns/{id}/click`
Registra un clic verificado y liquida el débito CPC atómico.
```json
{
  "eventId": "f1a83b2c-6d91-49e2-b715-9c520e18a302",
  "placementId": 1,
  "creativeId": 402,
  "timestamp": "2026-10-10T12:00:07Z"
}
```

**Respuestas:**
- `200 OK`: Evento procesado, saldo debitado exitosamente.
- `400 Bad Request`: Parámetros inválidos o saldo insuficiente.
- `409 Conflict`: `eventId` duplicado (rechazo por idempotencia).

---

## 3. Gestión de Campañas (Protegido por `SOLUSOL_AUTH_V1`)

### `GET /api/Campaigns`
Lista todas las campañas pertenecientes al `TenantId` autenticado.

### `POST /api/Campaigns`
Crea una nueva campaña publicitaria.
```json
{
  "name": "Lanzamiento Q4",
  "budget": 500.00,
  "costPerMille": 2.50,
  "costPerClick": 0.25,
  "startDate": "2026-10-01T00:00:00Z",
  "endDate": "2026-10-31T23:59:59Z"
}
```

### `POST /api/Campaigns/{id}/status`
Actualiza el estado de la campaña (`ACTIVE`, `PAUSED`, `COMPLETED`).
```json
{
  "status": "PAUSED"
}
```

### `GET /api/Campaigns/{id}/metrics`
Obtiene las métricas matemáticas reales consolidadas.
```json
{
  "campaignId": 101,
  "impressions": 12500,
  "clicks": 312,
  "ctr": 0.02496,
  "budgetSpent": 109.25,
  "remainingBudget": 390.75
}
```