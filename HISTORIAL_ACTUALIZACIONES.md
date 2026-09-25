# Historial de Actualizaciones - Proyecto ADSOLUSOL

## 2026-09-18 — Restauración de Calidad y Fiabilidad

### 🚀 Mejoras y Optimizaciones

*   **Restauración Completa de Pruebas de Regresión**:
    *   La suite de pruebas de regresión (`ADSOLUSOL.RegressionTests`) ha sido completamente restaurada desde un estado ficticio a una suite de validación de extremo a extremo con **17 comprobaciones numeradas de negocio**.
    *   Las pruebas ahora utilizan un host de aplicación real con inyección de dependencias y una base de datos en memoria para validar el flujo completo del sistema: creación de campañas, aislamiento de tenants, persistencia, servicio de anuncios, procesamiento de eventos, métricas y protección de presupuesto.
    *   El ejecutable de pruebas ahora devuelve un código de salida distinto de cero en caso de fallo, lo que garantiza que el script de auditoría (`AUDIT-ADSOLUSOL-ULTRA-SUPERCHISMOSO.ps1`) detecte los errores de forma fiable.

### 🐞 Corrección de Errores

*   **Pérdida de Datos en Asociaciones (`AssignmentRepository`)**:
    *   Se corrigió un error crítico donde las asociaciones entre campañas, placements y creativos no se guardaban en la base de datos, a pesar de que la API devolvía una respuesta exitosa. Ahora se garantiza la persistencia mediante `SaveChangesAsync`.
*   **Pérdida de Datos en Eventos (`AdEventRepository`)**:
    *   Se solucionó un bug donde los eventos procesados sin una transacción explícita no se guardaban en la base de datos. Ahora se asegura su persistencia en todos los casos.
*   **Error de Compilación en `ServeController`**:
    *   Se corrigió una llamada a un método inexistente (`GetAdAsync`) por el nombre correcto (`SelectAdForPlacement`), resolviendo un error de compilación que bloqueaba la API.
*   **Optimización en Selección de Anuncios (`AdServingService`)** (Previamente documentado):
    *   Se ha mejorado significativamente el rendimiento del servicio de selección de anuncios.
    *   La consulta a la base de datos (`GetEligibleCampaignsAsync`) ahora pre-filtra las campañas por estado `ACTIVO` y presupuesto disponible.
    *   Esto reduce la carga en la aplicación, que ahora solo necesita validar el rango de fechas de la campaña. (Ref: `FIX P1-05`)

*   **Protección de Presupuesto (`BudgetService`)**:
    *   Se implementó un mecanismo de actualización de presupuesto atómico y condicional para evitar que las campañas excedan su límite.
    *   El método `UpdateBudgetAsync` ahora garantiza que el débito de un costo no se aplique si resulta en un gasto mayor al presupuesto asignado.

*   **Cálculo de Costo en Eventos (`EventProcessingService`)** (Previamente documentado):
    *   Se corrigió un error donde el costo de un evento no se calculaba antes de ser procesado.
    *   Ahora, el costo se calcula y se asigna al objeto `AdEvent` inmediatamente después de validar el tipo de evento.
    *   Esto asegura que todos los sistemas subsecuentes, como el servicio de telemetría (`IMarketingBrainService`), reciban y registren el costo correcto. (Ref: `FIX P1-03`)

### 🔧 Cambios Internos

*   **Esquema de Base de Datos (`AppDbContext`)**: Se añadieron los `DbSet` para `Placement` y `Creative`, asegurando que el esquema de la base de datos se genere correctamente durante las pruebas.
*   **Tooling (`Health-Check.ps1`)**: Se corrigieron errores de sintaxis en el script de diagnóstico para asegurar su correcta ejecución.
*   **`ICampaignRepository`**: La interfaz fue actualizada con el método `UpdateBudgetAsync` para soportar las actualizaciones de presupuesto seguras.
*   **`EventProcessingService`**: El servicio ahora maneja el ciclo de vida completo de la transacción (Begin, Commit, Rollback) para garantizar la consistencia de los datos al procesar eventos.

## 2026-09-19 — Resolución de Compilación, Seguridad e Integraciones
### 🚀 Mejoras y Optimizaciones
*   **Cableado del Pipeline de Seguridad**:
    *   Se registró `SignatureVerificationMiddleware` en el pipeline HTTP de `Program.cs`.
    *   Se implementó la resolución autorizada de `TenantId` dentro del middleware basándose en la correspondencia del `NodeId` criptográfico validado.
    *   Se inyecta el `TenantId` en `HttpContext.Items["TenantId"]` de manera que todos los controladores críticos obtienen la identidad aislada y autenticada en runtime.
*   **Integración Real con Marketing Brain (SIC)**:
    *   Se eliminaron las simulaciones síncronas/mocks en `MarketingBrainClient`.
    *   Se implementó el cliente asíncrono real usando `HttpClient` y `IConfiguration` para enviar telemetría mediante peticiones POST y realizar verificaciones de disponibilidad activas de red.
*   **Cero Errores de Compilación**:
    *   Se resolvieron de manera integral todos los warnings y dependencias rotas del compilador, alcanzando un estado limpio de compilación (`Exit Code 0`) verificado.

## 2026-09-24 — Estabilización del Frontend Web y Diagnóstico de API/Persistencia
### 🚀 Mejoras y Optimizaciones
*   **Configuración del Panel Web React (`ADSOLUSOL.Presentation.Web`)**:
    *   Se implementó la configuración canónica en `vite.config.ts` integrando el plugin `@vitejs/plugin-react` y resolución ESM nativa mediante `node:url` para el alias `@/`.
    *   Configuración del proxy inverso para enrutar llamadas `/api` hacia Kestrel (`http://localhost:5000` o configurable por `VITE_API_BASE_URL`).
    *   Habilitación de `watch.usePolling: true` y `resolve.preserveSymlinks: true` en Vite para soportar ejecución sobre unidades de red o mapeadas (`Y:\` hacia `Q:\`), evitando errores de watcher del sistema de archivos (`errno: -4094`) y discrepancias de rutas absolutas durante la compilación de Rollup.

### 🐞 Corrección de Errores
*   **Conflicto de Referencias en TypeScript**:
    *   Se eliminó la referencia a `tsconfig.node.json` con `noEmit` en `tsconfig.json`, resolviendo el error `TS6310: Referenced project may not disable emit` durante `npm run build`.
*   **Inicialización y Migración del Esquema SQLite**:
    *   Se diagnosticó el fallo HTTP 500 y estado `database: DOWN` en `/api/health`. Se ejecutó la inicialización en entorno `Development` permitiendo a Entity Framework Core generar las tablas de persistencia (`Campaigns`, `AdEvents`, `Creatives`, `Placements`, `CampaignCreatives`, etc.).
*   **Liberación de Sockets en Kestrel**:
    *   Resolución del error `AddressInUseException (SocketException: 10048)` por procesos huérfanos ocupando el puerto 5000.

### 🔧 Alineación de Principios
*   **Zero-Synthetic en Telemetría y Salud**:
    *   Se ratifica que el check `sicEngine: DOWN` reporta honestamente la indisponibilidad de la red hacia el motor externo de Marketing Brain, sin simular disponibilidades ficticias en runtime.
