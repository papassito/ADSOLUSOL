# Interfaz Web 2027 (Raíz del Proyecto)

La interfaz web 2027 impulsada por la arquitectura de KLIK Soft Pro se ejecuta directamente desde la raíz mediante `npm install` y `npm run dev` (o `npm run dev:real` para conexión directa por proxy hacia ASP.NET Core en `http://localhost:5000`). `npm run build` genera `dist/` y `npm run lint` verifica TypeScript.

La entrega de anuncios (`/api/Serve`) y el débito atómico de impresiones/clics (`/api/Campaigns/{id}/click`, `/impression`) operan de forma autoritativa contra el backend Kestrel respetando la regla `BudgetSpent + Cost <= Budget` con identificadores idempotentes UUID v4. Las comprobaciones de salud consultan directamente `/api/health` sin interpolación sintética.

La conexión a https://api.solusol.net/api requiere confirmar sus contratos, autenticación, permisos y modelos de datos, y sustituir las rutas locales por servicios reales. La subasta, los débitos, las firmas Ed25519, la telemetría SIC, el bloqueo de términos, los datos iniciales, las métricas completadas y la proyección son simulados o calculados con valores supuestos. El análisis de URL y telemetría de componentes heredados carecen de rutas en el servidor de demostración. Las notificaciones solo funcionan mientras la interfaz está abierta y el navegador concede permiso. El enlace a Google Maps abre una página externa; no confirma que una persona haya llegado.

El archivo `.env.example` original se conserva en `adsolusol_2027/`; no se migran ni alteran credenciales. El servidor de demostración no implementa autenticación ni debe exponerse como servicio de producción.
