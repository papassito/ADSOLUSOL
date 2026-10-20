# Interfaz Web 2027 (Raíz del Proyecto)

La interfaz web 2027 impulsada por la arquitectura de KLIK Soft Pro se ejecuta directamente desde la raíz mediante `npm install` y `npm run dev`. `npm run build` genera `dist/` y `npm run lint` verifica TypeScript. Los componentes, constantes y tipados han sido consolidados en `src/`, conservando la solución .NET en `src/ADSOLUSOL.*`.

El servidor en `server/` es una demostración local, guarda datos en `adsolusol_enterprise_db.json` y no está conectado a producción. El archivo se crea al consultar el estado; no contiene datos reales por defecto. El modo de demostración puede modificar ese archivo mediante acciones y Auto-Live.

La conexión a https://api.solusol.net/api requiere confirmar sus contratos, autenticación, permisos y modelos de datos, y sustituir las rutas locales por servicios reales. La subasta, los débitos, las firmas Ed25519, la telemetría SIC, el bloqueo de términos, los datos iniciales, las métricas completadas y la proyección son simulados o calculados con valores supuestos. El análisis de URL y telemetría de componentes heredados carecen de rutas en el servidor de demostración. Las notificaciones solo funcionan mientras la interfaz está abierta y el navegador concede permiso. El enlace a Google Maps abre una página externa; no confirma que una persona haya llegado.

El archivo `.env.example` original se conserva en `adsolusol_2027/`; no se migran ni alteran credenciales. El servidor de demostración no implementa autenticación ni debe exponerse como servicio de producción.
