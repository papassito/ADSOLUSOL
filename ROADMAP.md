# ADSOLUSOL 2027 — Hoja de Ruta Canónica (Roadmap)

**Nivel:** 5 — Plan de Evolución e Implementación Soberana  
**Estado:** TARGET / VERIFICABLE  
**Propietario:** KlikSoft  
**Plataforma Central:** SOLUSOL Intelligence Center (SIC)  
**Portal y Dashboard:** `https://adsolusol.solusol.net`  
**API Canónica:** `https://api.solusol.net/api`  

---

## Principios Rectores de Ejecución

1. **Cero Dependencias Externas:** Exclusión total de librerías, rastreadores y redes publicitarias ajenas. Todo el tráfico y serving es First-Party.
2. **Servidor Autoritativo:** El backend (.NET 8) es la única entidad que liquida débitos presupuestarios y resuelve subastas.
3. **Zero Synthetic Metrics:** Prohibición absoluta de simular clics, impresiones o saldos.
4. **Notaría Criptográfica:** Validación obligatoria mediante firmas Ed25519 (`SOLUSOL_AUTH_V1`).

---

## Fase 1: Motor Base & Serving

*Objetivo: Consolidar el ciclo de vida de campañas y la entrega segura de creativos estáticos.*

- [x] **Dominio de Campañas:** Entidades `Campaign`, `Placement`, `Creative` y `Assignment`.
- [x] **Máquina de Estados Finita:** Estados estrictos (`SCHEDULED`, `ACTIVE`, `PAUSED`, `COMPLETED`, `ARCHIVED`) con validación de transiciones en `/api/Campaigns/{id}/status`.
- [x] **Contratos Seguros & CSP:** Validación de URLs seguras (`HTTPS`) y bloqueo de inyección JavaScript arbitraria en creativos.
- [x] **Ruta de Entrega Directa:** Endpoint canónico `GET /api/Serve?placementCode={code}`.

---

## Fase 2: Persistencia SQL & Débito Atómico

*Objetivo: Garantizar precisión financiera absoluta y protección contra sobregiros concurrentes.*

- [x] **Precisión Monetaria:** Representación con `DECIMAL(18,4)` de 128 bits. Eliminación de números binarios de coma flotante (`float`/`double`).
- [x] **Ledger Transaccional:** Débito condicional atómico `UPDATE Campaigns SET BudgetSpent = BudgetSpent + Cost WHERE Spent + Cost <= Budget`.
- [x] **Persistencia Híbrida:** Soporte para SQLite (modo WAL para nodos de borde/desarrollo) y compatibilidad directa con PostgreSQL para producción federada.
- [x] **Suite de Estrés Multihilo:** 20 pruebas de regresión automáticas comprobando la preservación del techo presupuestario ante colisiones masivas concurrentes.

---

## Fase 3: Subastas en Tiempo Real (RTB / eCPM) & Pacing

*Objetivo: Maximizar el rendimiento de los placements mediante subasta dinámica y control de frecuencia.*

- [ ] **Subasta Determinista eCPM:** Implementar en `AdServingService` la resolución en memoria para selección de ganador por eCPM efectivo:
  $$\text{eCPM} = \text{Puja CPM} \times \left(\frac{\text{CTR}}{100}\right) \times 1000$$
- [ ] **Alias de Compatibilidad RTB:** Exponer `GET /api/public/ad-request` como alias directo hacia la lógica de serving.
- [ ] **Frequency Capping:** Limitación de exposición por usuario (IP/nodo) con ventana deslizante de 24 horas para evitar la fatiga publicitaria.
- [ ] **Plan de Escalabilidad de Persistencia:** Documentar y probar el path de migración a PostgreSQL, incluyendo benchmarks de escritura concurrente para validar el rendimiento vs. SQLite en modo WAL.
- [ ] **Controlador de Pacing Dinámico:** Distribución del presupuesto a lo largo del día para evitar el agotamiento prematuro en las primeras horas.

---

## Fase 4: Telemetría First-Party & Analytics Engine

*Objetivo: Auditoría transparente, cálculo exacto de rendimiento e inmunidad a duplicados.*

- [ ] **Purga de Elementos Demo en Frontend:** Eliminar del bundle de producción cualquier componente, simulador o selector que emita datos sintéticos o simule subastas.
- [x] **Ingesta Idempotente:** Endpoints `/api/Campaigns/{id}/impression` y `/api/Campaigns/{id}/click` con deduplicación estricta por `event_id`.
- [x] **Cálculo Matemático de KPIs:** `MetricsService` calcula CTR real (`Clicks / Impressions`), gasto real acumulado y presupuesto remanente.
- [/] **Sprint 1 — Workbench Operativo (F1-F4) [EN CONSTRUCCIÓN]:** Arquitectura de 4 pisos ([F1] Crear, [F2] Operar, [F3] Auditar con Feed de Evidencia Comercial, [F4] Inventario integrado en Piso 3B) + Bandeja de Incidentes (INFO/WARN/CRITICAL). Estado: Diseñado, en fase de maquetación y cableado de APIs.
- [ ] **Sprint 2 — Wizard Rápido de Campaña:** Drawer modal interactivo con validación de precisión decimal, vigencias temporales y asociación a códigos de espacio normalizados.
- [ ] **Sprint 3 — Dashboard Analítico Profundo:** Panel analítico secundario (ROI, ROAS, CPM, CPC, mapas de calor de efectividad y embudos First-Party de circuito cerrado).
- [ ] **Reporte de Atribución:** Conciliación transparente de eventos sin extrapolación sintética de datos.

---

## Fase 5: Integración SIC (Marketing Brain)

*Objetivo: Interconexión resiliente con el centro de inteligencia de la red SOLUSOL.*

- [x] **Diagnóstico Coordinado:** Endpoint `/api/health` validando el estado local y la disponibilidad de `{SicBaseUrl}/health`.
- [x] **Cliente Asíncrono:** `MarketingBrainClient` enviando telemetría de eventos mediante peticiones REST.
- [ ] **Patrón Outbox Persistente:** Cola local persistente para garantizar la entrega de telemetría hacia SIC ante interrupciones prolongadas de red (garantía *At-Least-Once* sin degradar el serving).
- [ ] **Pruebas de Resiliencia de Red:** Simular fallos del SIC y verificar que el sistema sigue operando y encolando telemetría correctamente, cumpliendo el principio de `DISCONNECTED != AVAILABLE`.

---

## Fase 6: Motor IA & Antifraude IVT

*Objetivo: Protección del inventario frente a tráfico inválido y optimización asistida.*

- [ ] **Filtrado Antifraude IVT (Invalid Traffic):** Detección de patrones anómalos de clics rápidos desde la misma IP (granjas de clics) y bloqueo de User-Agents sospechosos.
- [ ] **Recomendador Publicitario Asistido (AI AD):** Generación de propuestas de copy, llamados a la acción (CTA) y distribución óptima de presupuestos.
- [ ] **Barrera Normativa:** `AI Recommendation != Authorized Mutation` (la IA sugiere; la autorización y ejecución financiera requieren aprobación humana/política).

---

## Fase 7: Federación Klik & Nodos Soberanos

*Objetivo: Descentralización del ad serving en múltiples nodos con notaría criptográfica.*

- [x] **Notaría Ed25519:** Verificación obligatoria de firmas con encabezados `X-Solusol-Node-Id`, `X-Solusol-Timestamp`, `X-Solusol-Nonce` y `X-Solusol-Signature`.
- [x] **Aislamiento Multi-Tenant Autoritativo:** Inyección segura de `TenantId` a partir del nodo firmante.
- [ ] **Consorcio Federado:** Sincronización de inventarios publicitarios entre nodos de la red sin pérdida de soberanía de datos.
- [ ] **Pruebas de Seguridad Activas:** Desarrollar suite de pruebas de integración que intente activamente explotar el middleware de seguridad, incluyendo ataques de replay (nonces duplicados), timestamps inválidos y firmas corruptas.

---

## Fase 8: Tortura Operativa

*Objetivo: Intentar romper ADSOLUSOL mediante la simulación de escenarios de estrés extremo para validar la resiliencia, consistencia y rendimiento del sistema bajo fuego real.*

- [ ] **Escenario A (Carga Masiva de Campañas):** Simular la creación y gestión de 10,000 campañas activas simultáneas.
- [ ] **Escenario B (Ráfaga de Impresiones):** Sostener una carga de 1 millón de impresiones en una hora, validando la capacidad de ingesta y el rendimiento de la base de datos.
- [ ] **Escenario C (Concurrencia y Caída Parcial):** Procesar 100,000 clics concurrentes mientras la dependencia del SIC se encuentra intermitente, verificando que el patrón Outbox previene la pérdida de telemetría.
- [ ] **Escenario D (Recuperación ante Desastres):** Forzar un reinicio inesperado del nodo API durante una escritura masiva de eventos y verificar la consistencia de los datos y el estado del ledger tras la recuperación.
- [ ] **Escenario E (Agotamiento de Presupuesto Concurrente):** Lanzar un ataque de alta concurrencia sobre una campaña con presupuesto a punto de agotarse para verificar que el gasto NUNCA excede el límite y que los eventos rechazados por falta de fondos se registran correctamente.

### Criterio de Aceptación "Enterprise Ready"

El sistema será considerado "Enterprise Ready" únicamente cuando demuestre haber sobrevivido una ejecución de **30 días continuos** bajo los escenarios de tortura, cumpliendo con:

- **Cero corrupción de datos:** El ledger financiero permanece íntegro.
- **Cero pérdida de telemetría:** Todos los eventos son eventualmente consistentes con el SIC.
- **Cero sobreconsumo de presupuesto:** Ninguna campaña gasta más de su límite asignado.
- **Cero duplicidades:** La idempotencia se mantiene bajo cualquier nivel de carga.

---

## Control de Calidad Operativa

Cada hito en esta hoja de ruta debe superar la siguiente barrera de calidad antes de considerarse cerrado:

```powershell
# 1. Compilación estricta sin advertencias
dotnet build ADSOLUSOL.sln -c Release

# 2. Validación de regresión funcional y ledger financiero
dotnet test tests/ADSOLUSOL.RegressionTests

# 3. Auditoría forense integral de todo el proyecto
powershell -File .\scripts\audit\audit_all_project.ps1
```
