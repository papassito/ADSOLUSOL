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
