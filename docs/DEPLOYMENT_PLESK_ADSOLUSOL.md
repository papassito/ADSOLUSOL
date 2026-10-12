# ADSOLUSOL en Plesk

El panel React (`ADSOLUSOL.Presentation.Web`) se compila localmente (`dist/`) y
se publica como archivos estáticos directamente en el Document Root de Plesk
(`httpdocs` o `adsolusol.solusol.net`). La API .NET corre como
`adsolusol-api.service` en `127.0.0.1:5000`; no debe exponerse ese puerto directamente a Internet.

## Acceso Directo al Workbench (Modo Construcción — Sin Login Temporal)

Durante la fase de construcción y estabilización de la interfaz, el portal web (`adsolusol.solusol.net`)
levanta directamente en el **Workbench Operativo** con acceso inmediato y sin fricción.
Se prescinde temporalmente de formularios interactivos de usuario y contraseña para agilizar
el desarrollo, verificación de rutas y prueba ágil de los flujos de trabajo en caliente.

El operador accede en 0 clics a las 4 acciones canónicas:
[F1] Nueva Campaña, [F2] Gestionar Pauta, [F3] Auditar Resultados y [F4] Inventario de Espacios.
La seguridad del sistema no reside en la autenticación del usuario final, sino en la
infraestructura: restricción de red por proxy y verificación criptográfica Ed25519 de máquina a máquina (`SOLUSOL_AUTH_V1`). Una vez concluida la construcción, se evaluará el cierre perimetral interactivo.

## Topología de enrutamiento Nginx en Plesk

La arquitectura de publicación requerida para los dominios es:

```text
adsolusol.solusol.net/  (Portal & Panel Web)
        │
        ├── /               → Presentation.Web (index.html)
        ├── /*              → Presentation.Web / index.html
        │
        └── /api/*          → Proxy hacia api.solusol.net (o backend local 127.0.0.1:5000)

api.solusol.net/        (API Canónica del Sistema)
        │
        ├── /api/*          → Presentation.Api (127.0.0.1:5000)
        └── /swagger/*      → Presentation.Api (127.0.0.1:5000)
```

En **Sitios web y dominios** > **Configuración de Apache y nginx** > **Directivas adicionales de nginx**,
configurar el bloque completo. Nunca incluir una regla `location = /` que apunte al puerto 5000:

```nginx
# API .NET
location ^~ /api/ {
    proxy_pass http://127.0.0.1:5000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection keep-alive;
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Swagger UI y endpoints de esquema
location = /swagger {
    proxy_pass http://127.0.0.1:5000;
}

location ^~ /swagger/ {
    proxy_pass http://127.0.0.1:5000;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# SPA Routing (Frontend React)
location / {
    try_files $uri $uri/ /index.html;
}
