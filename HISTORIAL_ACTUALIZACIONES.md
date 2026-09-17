# Historial de Actualizaciones - Proyecto ADSOLUSOL

## Versión [FECHA_ACTUAL]

### 🚀 Mejoras y Optimizaciones

*   **Optimización en Selección de Anuncios (`AdServingService`)**:
    *   Se ha mejorado significativamente el rendimiento del servicio de selección de anuncios.
    *   La consulta a la base de datos (`GetEligibleCampaignsAsync`) ahora pre-filtra las campañas por estado `ACTIVO` y presupuesto disponible.
    *   Esto reduce la carga en la aplicación, que ahora solo necesita validar el rango de fechas de la campaña. (Ref: `FIX P1-05`)

*   **Protección de Presupuesto (`BudgetService`)**:
    *   Se implementó un mecanismo de actualización de presupuesto atómico y condicional para evitar que las campañas excedan su límite.
    *   El método `UpdateBudgetAsync` ahora garantiza que el débito de un costo no se aplique si resulta en un gasto mayor al presupuesto asignado.

### 🐞 Corrección de Errores

*   **Cálculo de Costo en Eventos (`EventProcessingService`)**:
    *   Se corrigió un error donde el costo de un evento no se calculaba antes de ser procesado.
    *   Ahora, el costo se calcula y se asigna al objeto `AdEvent` inmediatamente después de validar el tipo de evento.
    *   Esto asegura que todos los sistemas subsecuentes, como el servicio de telemetría (`IMarketingBrainService`), reciban y registren el costo correcto. (Ref: `FIX P1-03`)

### 🔧 Cambios Internos

*   La interfaz `ICampaignRepository` fue actualizada con el método `UpdateBudgetAsync` para soportar las actualizaciones de presupuesto seguras.
*   El servicio `EventProcessingService` ahora maneja el ciclo de vida completo de la transacción (Begin, Commit, Rollback) para garantizar la consistencia de los datos al procesar eventos.