# COMPONENTS ADSOLUSOL 2027

**Nivel:** 5 — Desacoplamiento Modular y Responsabilidad Única (SRP)  
**Propósito:** Definir los límites de responsabilidad e invariantes de cada módulo del sistema publicitario sovereign para evitar contaminación arquitectónica.

---

## 1. CampaignManager (`CampaignService` / `CampaignsController`)
- **Responsabilidad:** Administrar el ciclo de vida de campañas (`SCHEDULED`, `ACTIVE`, `PAUSED`, `COMPLETED`), validación de vigencias y metadatos comerciales.
- **NO DEBE:**
  - Calcular CTR o agregaciones de métricas en caliente.
  - Almacenar telemetría de eventos en crudo.
  - Mutar directamente el balance gastado sin pasar por el servicio de débito atómico.

---

## 2. Auction & Serving Engine (`AdServingService` / `ServeController`)
- **Responsabilidad:** Filtrar campañas elegibles por placement, vigencia y presupuesto remanente. Resolver la entrega óptima de creativos aplicando algoritmo de pacing ponderado.
- **NO DEBE:**
  - Registrar cobros financieros en el momento de la entrega (el cobro sólo ocurre con la confirmación del evento verificado).
  - Ejecutar scripts de rastreo de terceros no autorizados.
  - Entregar creativos de campañas inactivas o con presupuesto agotado.

---

## 3. Telemetry Engine (`EventProcessingService`)
- **Responsabilidad:** Ingesta de eventos de impresión y clic, validación estricta de idempotencia mediante `event_id`, cálculo del costo del evento (CPM/CPC) y coordinación transaccional.
- **NO DEBE:**
  - Permitir procesamiento de eventos duplicados (doble cobro).
  - Tolerar números de coma flotante binaria (`float`/`double`) para liquidación monetaria.
  - Modificar metadatos de campaña ajenos al costo del evento.

---

## 4. Budget Ledger (`BudgetService` / `CampaignRepository.UpdateBudgetAsync`)
- **Responsabilidad:** Garantizar atomicidad transaccional e integridad presupuestaria mediante débitos condicionales (`BudgetSpent + Cost <= Budget`).
- **NO DEBE:**
  - Permitir sobregiros presupuestarios bajo condiciones de alta concurrencia multihilo.
  - Confirmar un débito si la base de datos no afectó filas de manera certera (`rowsAffected > 0`).
  - Delegar la lógica de débito al frontend.

---

## 5. Analytics Engine (`MetricsService`)
- **Responsabilidad:** Consolidar impresiones y clics verificados, calcular CTR real (`Clicks / Impressions`), balance gastado y presupuesto remanente.
- **NO DEBE:**
  - Generar métricas sintéticas o estimaciones ficticias cuando falten datos (debe reportar `NO_DATA` o `0`).
  - Mutar el estado de las campañas ni el ledger financiero.
  - Absorber métricas ajenas al dominio publicitario (tales como analítica SEO o Core Web Vitals).

---

## 6. Security & Cryptographic Barrier (`SignatureVerificationMiddleware`)
- **Responsabilidad:** Autenticar peticiones mediante verificación criptográfica de firmas Ed25519, validar timestamps dentro de ventana de tolerancia y rechazar nonces repetidos.
- **NO DEBE:**
  - Asumir autorización de recursos por el mero hecho de una firma válida (*Authentication != Authorization*).
  - Permitir bypass de firmas en endpoints protegidos.
  - Exponer secretos o claves privadas en logs.

---

## 7. Gobernanza de Interfaces y Autoridad Canónica

Rige el principio arquitectónico: **Una función → Un dueño → Una pantalla canónica**. Se prohíbe la coexistencia de dashboards o pantallas de diagnóstico concurrentes con fuentes de verdad divergentes.

### Triada de Verdades del Ecosistema
1. **Business Truth (Verdad de Negocio):** Pertenece a `Presentation.Web`. Estado de campañas, facturación, pacing y entrega de creativos.
2. **Operational Truth (Verdad Operativa):** Pertenece a `Presentation.Desktop`. Estado de borde, persistencia local SQLite y autonomía fuera de línea.
3. **Engineering Truth (Verdad de Ingeniería):** Pertenece a `Santiago / Checador`. Sanidad del código, sellos criptográficos, pruebas de arquitectura e invariantes.

### Regla de Asimetría Productor-Consumidor
- La Consola Comercial (`Presentation.Web`) **puede consumir y desplegar pasivamente** los metadatos o sellos de certificación producidos por Santiago (e.g., Badge de Certificación Nivel 5, fecha de último peritaje, SHA de commit verificado).
- La Consola Comercial **NUNCA DEBE ejecutar** scripts de auditoría (`audit_all_project.ps1`), suites de regresión ni invocar herramientas forenses (`CodeAuditorView`, `TestSuiteRunnerView`).

### A. Consola Comercial Web (`ADSOLUSOL.Presentation.Web`)
- **Dueño Exclusivo:** Operación comercial publicitaria en caliente (`https://adsolusol.solusol.net`).
- **Alcance:** Confinado al Workbench Operativo Canónico de Acceso Directo ([F1] Crear, [F2] Operar, [F3] Auditar, [F4] Inventario de Espacios y Sitios) con cero barreras de login interactivo, más las vistas de soporte (`Dashboard`, `Placements`, `Creatives`, `Assignments`, `Serve`, `System`, `Settings`).
- **Salud (Health):** Exclusivamente **Salud de Runtime** (`/api/health`: disponibilidad de HTTP, base de datos local y conectividad con SIC).
- **NO DEBE:** Alojar herramientas de ingeniería, exploradores de archivos del repositorio, ejecutores de suites de prueba (`TestSuiteRunnerView`), analizadores de AST ni visores de código fuente (`CodeAuditorView`).

### B. Consola Soberana de Nodo (`ADSOLUSOL.Presentation.Desktop`)
- **Dueño Exclusivo:** Operación de borde (Edge/Offline-First) en estaciones de trabajo aisladas (.NET MAUI Blazor).
- **Alcance:** Interacción directa sobre la persistencia local SQLite (`adsolusol.db` en `AppDataDirectory`).
- **NO DEBE:** Replicar la administración multi-tenant centralizada ni actuar como consola de desarrollo.

### C. Consola de Notaría e Ingeniería (`Santiago / Checador`)
- **Dueño Exclusivo:** Auditoría forense, aseguramiento de calidad (QA), certificación Nivel 5 y DevOps.
- **Alcance:** Inspección estática de código, verificación de invariantes Onion, detección de falsos positivos/negativos, validación de sellos SHA-256 (`MANIFEST.md`) y ejecución de suites (`audit_all_project.ps1`).
- **Salud (Health):** Exclusivamente **Salud Estructural** (integridad de capas, compilación y pruebas de regresión).
- **NO DEBE:**
  - Alojar formularios de creación de campañas comerciales ni gestionar transacciones de facturación.
  - Tomar decisiones financieras autoritativas.
  - Modificar respuestas de la API antes de presentarlas al usuario.