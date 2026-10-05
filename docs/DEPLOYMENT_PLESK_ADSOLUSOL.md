# ADSOLUSOL en Plesk

El panel React (`ADSOLUSOL.Presentation.Web`) se compila localmente (`dist/`) y
se publica como archivos estáticos directamente en el Document Root de Plesk
(`httpdocs` o `adsolusol.solusol.net`). La API .NET corre como
`adsolusol-api.service` en `127.0.0.1:5000`; no debe exponerse ese puerto directamente a Internet.

## Autenticación del panel

Cada tenant autorizado necesita un hash PBKDF2 independiente en la configuración
del servicio, con clave `PanelAuth__Tenants__<tenantId>`. Nunca guardar la
contraseña en `appsettings.json`, Git, ni en los archivos públicos de Plesk.
El formato del hash es `pbkdf2-sha256:310000:<salt base64>:<hash base64>`.
Sin una entrada configurada, ese tenant no puede iniciar sesión.

Las cookies del panel son HttpOnly, Secure, SameSite=Strict, con ticket firmado
y cifrado mediante ASP.NET Core Data Protection. Las claves se conservan en
`/var/www/adsolusol-api/App_Data/keys`; respaldar ese directorio, asignarlo a
`www-data` y restringirlo a modo 0700. Conservar también
`App_Data/adsolusol.db` al actualizar los binarios.

`POST /api/auth/session` exige `tenantId` y `password`; `GET` comprueba la
sesión y `DELETE` cierra la sesión. Las operaciones máquina-a-máquina siguen
aceptando las cabeceras firmadas existentes. Una cookie antigua o un ID de
tenant sin contraseña ya no otorgan acceso.

## Topología de enrutamiento Nginx en Plesk

La arquitectura de publicación requerida para el subdominio es:

```text
adsolusol.solusol.net/
        │
        ├── /               → Presentation.Web (index.html)
        ├── /login          → Presentation.Web (try_files -> index.html)
        ├── /*              → Presentation.Web / index.html
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
```

No aplicar la regla hasta que el backend reparado esté activo y se haya probado
con tenant/contraseña válidos. Después verificar HTTPS, `/api/health` (200),
sesión sin credenciales (401), sesión válida, acceso a campañas del propio
tenant y rechazo de cookies falsificadas. Si falla, retirar la regla de nginx
y restaurar el binario anterior conservando SQLite y las claves de sesión.
