# ADSOLUSOL 2027 — Guía Canónica de Despliegue

**Entornos soportados:** Docker / Kubernetes / Windows Service (.NET Kestrel)

---

## 1. Despliegue con Docker Compose

El archivo `docker-compose.yml` orquesta la API de ADSOLUSOL junto con el motor SIC en una red aislada:

```bash
# 1. Construir e iniciar contenedores en segundo plano
docker compose up -d --build

# 2. Inspeccionar logs en tiempo real
docker compose logs -f adsolusol-api

# 3. Comprobar estado de salud
curl -s http://localhost:5000/api/health | jq .
```

---

## 2. Variables de Entorno de Producción

| Variable | Valor Típico | Descripción |
|---|---|---|
| `ASPNETCORE_ENVIRONMENT` | `Production` | Entorno de ejecución ASP.NET Core. |
| `ASPNETCORE_HTTP_PORTS` | `8080` | Puerto interno del contenedor Kestrel. |
| `ConnectionStrings__DefaultConnection` | `Data Source=/app/data/adsolusol.db` | Ruta SQLite o conexión PostgreSQL. |
| `SolusolAuthV1__SicBaseUrl` | `http://solusol.net:8080` | Endpoint base para consultas de SIC Engine. |
| `MarketingBrain__BaseUrl` | `http://solusol.net:8080` | Endpoint para ingesta de telemetría hacia SIC. |
| `INIT_SQLITE_SCHEMA` | `true` | Crea automáticamente el esquema en el primer arranque. |

---

## 3. Configuración de Proxy Inverso (Nginx)

```nginx
# 1. API Canónica: api.solusol.net
server {
    listen 80;
    server_name api.solusol.net;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Bypass de caché estricto para subastas y telemetría
        proxy_no_cache 1;
    }
}

# 2. Dashboard y Portal Web: adsolusol.solusol.net
server {
    listen 80;
    server_name adsolusol.solusol.net;
    root /var/www/adsolusol/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ^~ /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Bypass de caché estricto para subastas y telemetría
        proxy_no_cache 1;
    }
}
```