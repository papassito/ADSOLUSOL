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
