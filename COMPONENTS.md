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

## 7. Presentation Layer (`ADSOLUSOL.Presentation.Web` & `Desktop`)
- **Responsabilidad:** Visualización transparente del estado de campañas, creativos y rendimiento de inventario.
- **NO DEBE:**
  - Tomar decisiones financieras autoritativas.
  - Modificar respuestas de la API antes de presentarlas al usuario.