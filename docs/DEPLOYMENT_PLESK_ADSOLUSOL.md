# ADSOLUSOL en Plesk

El frontend LIVE es la aplicación Vite del directorio raíz del repositorio (src/).
Plesk debe compilarla y publicar el resultado de dist/ en cada despliegue. La API .NET
corre como adsolusol-api.service en 127.0.0.1:5000; no debe exponerse ese puerto directamente a Internet.

La vista autenticada /api/panel la devuelve la API desde
<ContentRoot>/panel/index.html. Por eso, actualizar el commit de Git no basta:
también hay que reconstruir el frontend, publicar sus recursos en el Document Root
y colocar el nuevo index.html en el directorio que lee la API.

## Autenticación Git mediante Deploy Key SSH

Para evitar fallos por autenticación interactiva HTTPS con GitHub, el repositorio bare en el servidor (`/var/www/vhosts/solusol.net/git/ADSOLUSOL`) debe configurarse con una clave SSH dedicada:

```bash
ssh-keygen -t ed25519 -C "plesk-adsolusol" -f /root/.ssh/id_adsolusol -N ""
cat /root/.ssh/id_adsolusol.pub # Registrar en GitHub -> Settings -> Deploy keys
git config core.sshCommand "ssh -i /root/.ssh/id_adsolusol -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
git remote set-url origin git@github.com:papassito/ADSOLUSOL.git
```

## Publicar el frontend en cada despliegue

El repositorio incluye npm run deploy:plesk. Este comando:

1. instala las dependencias bloqueadas con npm ci y ejecuta npm run build;
2. confirma que el bundle contiene la tarjeta “Verificar sitio promocionado”;
3. publica dist/ en el Document Root sin borrar otros archivos del sitio;
4. copia dist/index.html a <ContentRoot>/panel/index.html, que usa /api/panel;
5. escribe release.json en el Document Root con el commit y la hora UTC de publicación.

En Plesk, identifica las dos rutas:

- **Document Root**: Sitios web y dominios → Hosting y DNS → Hosting → raíz de documentos.
- **ContentRoot de la API**: revisa systemctl cat adsolusol-api.service y el valor WorkingDirectory del servicio. La ruta de destino es ese ContentRoot más /panel. Si el servicio define --contentRoot, usa esa ruta explícita.

En **Git → Repositorio → Repository Settings → Additional deployment actions**, agrega esta acción para que se ejecute después de cada actualización. Invoca el script directamente con Bash: el script añade `/opt/plesk/node/20/bin` al `PATH`, de modo que Plesk no necesita resolver `npm` al iniciar la acción. Sustituye los ejemplos por las rutas reales de esa suscripción:

```bash
cd /var/www/vhosts/solusol.net/adsolusol.solusol.net && GIT_COMMIT="$(git --git-dir=/var/www/vhosts/solusol.net/git/ADSOLUSOL rev-parse --short=12 HEAD 2>/dev/null || echo unknown)" ADSO_WEB_ROOT="/var/www/vhosts/solusol.net/adsolusol.solusol.net" ADSO_API_PANEL_DIR="/var/www/adsolusol-api/panel" /bin/bash /var/www/vhosts/solusol.net/adsolusol.solusol.net/scripts/plesk-build-publish.sh
```

La acción necesita Node.js/npm, conexión para descargar dependencias y permiso de escritura del usuario de despliegue en ambas rutas. El script establece rutas de sistema y no depende de `dirname`, porque el `PATH` de la acción de Plesk puede estar vacío o incompleto. Obtén el **DocumentRoot absoluto** desde Sitios web y dominios → Hosting y DNS → Hosting; no lo deduzcas del nombre del dominio. Antes de volver a desplegar, verifica como administrador que ambas rutas existan (`test -d "/RUTA/REAL/DEL/DOCUMENTROOT"` y `test -d "/RUTA/REAL/DEL/CONTENTROOT/panel"`). En Plesk, confirma que el **usuario del sistema** de la suscripción tenga acceso al directorio `panel`; si actualmente pertenece a `root`, como administrador ejecuta `chown -R USUARIO_PLESK:psacln "/RUTA/REAL/DEL/CONTENTROOT/panel"`, sustituyendo el usuario y la ruta reales. Limita el cambio a ese directorio, no al ContentRoot completo. Si la compilación, la comprobación del bundle o la publicación falla, el script termina con error y Plesk debe mostrarlo en el registro de la acción. No reporta éxito antes de completar la copia.

Después de desplegar, comprueba en el registro Published commit <hash>. Abre https://adsolusol.solusol.net/release.json y confirma que el commit coincida. En la sesión autenticada, vuelve a abrir /api/panel?rev=<hash>, entra a **Estudio de Creativos + GPS + Verificación** y confirma que aparece **Verificar sitio promocionado**. El archivo release.json verifica el artefacto del Document Root; la tarjeta en /api/panel confirma que también se actualizó el HTML que sirve la API.

## Acceso al Workbench

Durante la fase de construcción y estabilización de la interfaz, el portal web (adsolusol.solusol.net)
levanta directamente en el **Workbench Operativo** con acceso inmediato y sin fricción.
La seguridad reside en el perímetro de infraestructura, proxy inverso y notaría criptográfica Ed25519 de máquina a máquina (SOLUSOL_AUTH_V1).

## Topología de enrutamiento Nginx en Plesk

La arquitectura de publicación requerida para los dominios es:

```text
adsolusol.solusol.net/
        ├── /             → Document Root con el build Vite
        ├── /*            → SPA: /index.html
        └── /api/*        → API .NET (127.0.0.1:5000)
                              /api/panel sirve <ContentRoot>/panel/index.html

api.solusol.net/
        ├── /api/*        → API .NET (127.0.0.1:5000)
        └── /swagger/*    → API .NET (127.0.0.1:5000)
```

En **Sitios web y dominios** > **Configuración de Apache y nginx** > **Directivas adicionales de nginx**,
configurar el bloque completo. Nunca incluir una regla location = / que apunte al puerto 5000:

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
