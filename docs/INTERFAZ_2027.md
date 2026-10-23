# Interfaz Web 2027 (Raíz del Proyecto)

La interfaz web 2027 impulsada por la arquitectura de KLIK Soft Pro se ejecuta directamente desde la raíz mediante `npm install` y `npm run dev` (o `npm run dev:real` para conexión directa por proxy hacia ASP.NET Core en `http://localhost:5000`). `npm run build` genera `dist/` y `npm run lint` verifica TypeScript.

La entrega de anuncios (`/api/Serve`) y el débito atómico de impresiones/clics (`/api/Campaigns/{id}/click`, `/impression`) operan de forma autoritativa contra el backend Kestrel respetando la regla `BudgetSpent + Cost <= Budget` con identificadores idempotentes UUID v4. Las comprobaciones de salud consultan directamente `/api/health` sin interpolación sintética.

La conexión con la API autoritativa (puerto 5000 / proxy /api/) opera directamente contra Kestrel y SQLite en modo WAL. La entrega de creativos, la validación de vigencias temporales, el aislamiento multi-tenant por firma Ed25519 y la liquidación presupuestaria son ejecutados en backend sin componentes sintéticos, garantizando el principio Zero-Synthetic Metrics (REQ-DATA-001 a REQ-DATA-005). Las notificaciones de umbral presupuestario al 90% se emiten en base a los saldos reales confirmados en el ledger.

El archivo `.env.example` original se conserva en `adsolusol_2027/`; no se migran ni alteran credenciales. El servidor de demostración no implementa autenticación ni debe exponerse como servicio de producción.
