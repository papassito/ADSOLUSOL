# Historial de Actividades del Proyecto ADSOLUSOL

**STATUS: HISTORICAL LOG / SUPERSEDED FOR CURRENT-STATE CLAIMS**

Este archivo conserva afirmaciones, auditorías y sellos de etapas anteriores. Las etiquetas `OPERATIVE VERIFIED`, resultados de pruebas, rutas API, hallazgos de SIC y cualquier otro estado aquí registrado **no certifican el runtime actual**. Para el estado vigente usar `README.md`, `docs/contracts/MARKETING-API.md`, `docs/STRUCTURE.md` y evidencia de ejecución reciente.

---

Este documento registra los hallazgos, acciones de corrección y decisiones clave tomadas durante el ciclo de auditoría y desarrollo del proyecto.

---

### 1. Revisión y Hallazgos Iniciales (Auditorías 12–14 Sep)

Durante la primera fase de revisión, las auditorías automáticas y manuales identificaron varios bloqueos críticos que impedían el funcionamiento y la integridad del sistema.

*   **`[CRITICAL] ADS-BUILD-001`:** El proyecto no compilaba (`dotnet build` fallaba).
*   **`[CRITICAL]` Seguridad:** Una clave privada criptográfica fue encontrada expuesta en el historial de commits.
*   **`[CRITICAL] ADS-API-002`:** Los endpoints principales (`/toggle`, `/click`, `/impression`) no estaban implementados y devolvían códigos de error `503 Service Unavailable` o eran stubs.
*   **`[DESCARTADO PARA ADSOLUSOL] SIC-NET-001`:** Este hallazgo pertenecía a una auditoría de SOLUSOL SIC y fue incorporado erróneamente al historial de ADSOLUSOL. No forma parte del baseline ni del estado técnico vigente de este proyecto.
*   **`[WARNING] WARNING_MISSING_CRITICAL`:** Los respaldos de seguridad del proyecto se reportaron como incompletos en esa etapa histórica.
*   **`[DESCARTADO PARA ADSOLUSOL] SIC-DOC-001`:** La referencia a `NODE_CONTRACT.md`, `AUTHENTICATION_CONTRACT.md` y otros contratos de SIC fue una contaminación documental. Esos documentos no constituyen requisitos faltantes de ADSOLUSOL.

---

### 2. Acciones de Corrección y Verificación (15–17 Sep)

El equipo de desarrollo abordó los problemas críticos con alta prioridad, logrando los siguientes resultados verificados en el historial de actividades y ejecuciones de CI.

*   **`[RESUELTO]` Fallo de Compilación:** Se corrigieron los errores de código que impedían la compilación. Las pruebas `build`, `test` y el script `final-runtime-verification.ps1` ahora se ejecutan exitosamente.
*   **`[RESUELTO]` Endpoints No Implementados:** Se construyó e integró la lógica para los endpoints de eventos. Ahora son operativos de extremo a extremo, utilizando los servicios `AdServingService`, `BudgetService` y `MetricsService`.
*   **`[MITIGADO]` Exposición de Claves:** La clave privada expuesta fue inmediatamente revocada y rotada. Se eliminó del árbol de trabajo actual (`HEAD`), quedando solo como un registro histórico en commits antiguos.

---

### 3. Análisis Arquitectónico y Refactorización (17 Sep)

Tras la resolución de los bloqueos, una revisión más profunda del código reveló una inconsistencia arquitectónica.

*   **Hallazgo:** Se identificó una definición duplicada del enumerador `EventType`, una en la capa de `Application` y otra en la de `Domain`. Esto violaba el principio de "fuente única de verdad" de la Arquitectura Cebolla, donde los conceptos de negocio fundamentales deben residir en el Dominio.
*   **Acción de Corrección:**
    1. Se consolidó el `enum EventType` moviéndolo a `ADSOLUSOL.Domain.Enums`.
    2. Se actualizaron los servicios que lo consumían (ej. `EventProcessingService`) para que todos apunten a la definición única en el Dominio.
    3. Esta acción previene futuros bugs de consistencia y fortalece la cohesión del núcleo del negocio.

---

### 4. Corrección posterior de alcance

Una revisión posterior determinó que los hallazgos `SIC-NET-001` y `SIC-DOC-001` procedían de SOLUSOL SIC y habían sido incorporados erróneamente al historial de ADSOLUSOL. Se conservan arriba únicamente como registro histórico de esa contaminación y quedan formalmente descartados como requisitos o pendientes de este producto.

Los pendientes técnicos vigentes de ADSOLUSOL deben obtenerse del `README.md` y de la documentación actual pre-sello. Entre ellos se encuentran:

* integración de la UI de producción con ASP.NET / `wwwroot`;
* configuración definitiva de SQLite para Production y datos instalados;
* estrategia segura de actualización/versionado de esquema;
* conexión del middleware de autenticación;
* resolución y autorización de `TenantId`;
* aislamiento tenant integral;
* integración real o estado explícito `DISCONNECTED` de Marketing Brain/SIC;
* `dotnet publish` reproducible;
* instalador y verificación posterior a instalación.

Este historial no sustituye la fuente de estado vigente.

---

### 5. Recuperación y alineación de producción (15 Oct 2026)

Se reconstruyó el acceso centralizado a AdSolusol desde fuentes, alineando los repositorios, los artefactos Release y los servicios desplegados. No se modificaron bases de datos, configuración de producción ni llaves.

**Portal central y SSO**

* Se recuperó y versionó en `SOLUSOL_NET/portal-core/` el módulo GoFiber que estaba presente en el VPS, pero ausente del checkout local. El portal central conserva su autenticación propia por cookie y expone `GET /adsolusol/sso` solo bajo `AuthGuard`.
* El portal genera un ticket HMAC de un minuto con correo, expiración y nonce aleatorio; su formulario lo entrega por POST a `https://adsolusol.solusol.net/api/auth/solusol-sso`.
* ADSOLUSOL valida firma, expiración, nonce de un solo uso, correo y tenant; emite la cookie segura `ADSOLUSOL.Panel` y devuelve al dashboard central con `?adsolusol=connected`.
* El dashboard central muestra el iframe privado solo después del handoff SSO. El vhost de ADSOLUSOL redirige `/` y `/index.html` a `https://solusol.net/dashboard`; `/panel` redirige al shell protegido `/api/panel`. El acceso anónimo a `/api/panel` devuelve 401.
* El módulo `auth_request` no está disponible en el Nginx de este VPS. Se usó en su lugar un endpoint ASP.NET protegido por el middleware de sesión, sin debilitar la política de autenticación.

**API, inventario y creativos**

* ADSOLUSOL quedó en `main`, commit `8cd7d80` (`feat(panel): connect central SSO, creative assets and placements`). SOLUSOL_NET quedó en `main`, commit `e2e199b` (`feat(portal): restore central AdSolusol SSO bridge`). Ambos commits están publicados en `origin/main`.
* Se reconstruyó y desplegó la API ASP.NET desde `8cd7d80`. `/api/health` responde 200 `Healthy`, con base de datos y SIC en `UP`.
* El formulario y el dashboard usan `GET /api/Placements`, existente en el backend. Se retiró el mapa geográfico decorativo y se muestra “Sin datos geográficos” cuando no existe telemetría.
* Se añadió carga autenticada de creativos PNG, JPEG y WebP, hasta 5 MB por archivo y 20 cargas por hora/IP. Se valida la firma binaria; los archivos reciben nombre aleatorio y se sirven como solo lectura, con `nosniff` y CSP. SVG y archivos con extensión/tipo falsos se rechazan.
* El cliente de upload conserva la URL si falla la creación del creativo. El formulario permite cargar imagen o proporcionar URL y muestra la imagen creada.

**Verificación**

* `dotnet test` regresión: 10/10; arquitectura: 2/2.
* `go test ./...` en `portal-core`: todas las suites pasan; build Linux amd64 realizado con `CGO_ENABLED=0`.
* `npm run build -- --outDir %TEMP%\adsolusol-final-web`: PASS.
* Pruebas de upload aisladas: login 200; PNG válido 200; URL de imagen 200 con `image/png`; archivo no imagen 400. `/api/panel` aislado devolvió 401 sin sesión y 200 con cookie.
* En navegador se confirmó `/dashboard?adsolusol=connected`, iframe cargado con tenant `tenant_02`, estado API `HEALTHY`, campañas y placement real visibles, sin errores JavaScript.
* En producción, `/` redirige al dashboard central, `/panel` redirige al endpoint privado, `/api/panel` anónimo responde 401 y `/api/health` responde 200. El login SSO anónimo devuelve el redirect esperado a `/login`.
* `nginx -t` pasó antes del reload. GoFiber y `adsolusol-api` quedaron activos después del despliegue.

**Backups de producción**

* `/root/backup-solusol-portal-source-before-e2e199b.tgz`
* `/root/backup-solusol-core-before-e2e199b`
* `/root/backup-adsolusol-api-before-8cd7d80.tgz`
* `/root/backup-adsolusol-web-before-8cd7d80.tgz`
* `/root/backup-adsolusol-vhost-before-8cd7d80.conf`

**Pendientes operativos**

* Una consulta real a Ad Serving para el placement existente devolvió `NO_AD_AVAILABLE`; falta cargar un creativo real y asociarlo a una campaña activa y al placement. No se generaron anuncios ni eventos ficticios.
* El backend conserva rutas para registrar clics e impresiones, pero el tag público/serving aún no las emite automáticamente.
* SEO externo, Google Ads y Google Maps no están activados; requieren proveedor, cuentas, credenciales y consentimiento/telemetría apropiados.
* El browser smoke de la carga de archivos fue bloqueado por la política de origen al usar `localhost`; el endpoint sí se probó directamente con el origen permitido en el entorno local aislado.

Los cambios locales preexistentes de `docs/EXPEDIENTE_CLINICO_MAESTRO.md`, `dist/index.html`, archivos `.old`, `.vscode/` y `smoke-test.ps1` se conservaron y no se incluyeron en los commits.
