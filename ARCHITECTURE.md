# ADSOLUSOL 2027 — Arquitectura del Sistema

**Nivel:** 5 — Arquitectura Canónica y Flujo de Datos  
**Patrón:** Onion Architecture (Clean Architecture) / Server-Authoritative Ledger  

---

## 1. Topología de Capas

```text
[ Clientes Web / Desktop / SDK First-Party ]
                     │
                     ▼ HTTP (JSON / Ed25519 Headers)
[ Presentation Layer: ASP.NET Core Web API / React Web / MAUI Blazor ]
                     │
                     ▼ (DTOs / Command Dispatch)
[ Application Layer: Services, Validations & Orchestration ]
   ├─ AdServingService (Subasta y Selección Ponderada)
   ├─ EventProcessingService (Ingesta Idempotente de Eventos)
   ├─ BudgetService (Débito Condicional Atómico)
   └─ MetricsService (Cálculo Determinista de KPIs)
                     │
                     ▼ (Interfaces / Entities)
[ Domain Layer: Entidades Puras, Enumeraciones, Reglas de Negocio ]
                     │
                     ▼ (Implementaciones de Persistencia y Clientes)
[ Infrastructure Layer: EF Core, Dapper, SQLite / PostgreSQL, SIC Client ]
```

---

## 2. Flujo de Datos: Solicitud y Servicio de Anuncios (Serving)

```text
Visitante / WebApp               ADSOLUSOL Serve API              AdServingService             Database
       │                                │                                │                         │
       │── GET /api/Serve?placement ───>│                                │                         │
       │                                │── SelectAdForPlacement ───────>│                         │
       │                                │                                │── GetEligible(Code) ───>│
       │                                │                                │<─ Active Campaigns ─────│
       │                                │                                │                         │
       │                                │                                │ [Verifica Vigencia]     │
       │                                │                                │ [Verifica Saldo > 0]    │
       │                                │                                │ [Aplica Pacing]         │
       │                                │<── Devuelve AdCreativePayload ─│                         │
       │<─ HTTP 200 (JSON + CSP Safe) ──│                                │                         │
```

---

## 3. Flujo de Datos: Ingesta Transaccional de Eventos y Débito

```text
Frontend / SDK First-Party              EventProcessingService            BudgetService             Database Ledger
            │                                     │                             │                          │
            │── POST /api/Campaigns/{id}/click ──>│                             │                          │
            │   (event_id, timestamp, signature)  │                             │                          │
            │                                     │── Deduplicar event_id ────────────────────────────────>│
            │                                     │   [Si ya existe -> 409 Conflict o Ignore Idempotente]  │
            │                                     │                                                        │
            │                                     │── BeginTransactionAsync ──────────────────────────────>│
            │                                     │                             │                          │
            │                                     │── DebitEventCostAsync ─────>│                          │
            │                                     │   (Costo calculado CPC/CPM) │── UPDATE Campaigns ─────>│
            │                                     │                             │   SET BudgetSpent += Cost│
            │                                     │                             │   WHERE Spent+Cost<=Cap  │
            │                                     │<─ Aprobado (rows == 1) ─────│                          │
            │                                     │                                                        │
            │                                     │── InsertAdEventAsync ─────────────────────────────────>│
            │                                     │── CommitTransactionAsync ─────────────────────────────>│
            │                                     │                             │                          │
            │                                     │── ReportToMarketingBrain(SIC) (Fire & Forget / Queue) ─> SIC Engine
            │<─ HTTP 200 Accepted ────────────────│
```

---

## 4. Frontera de Red y Ecosistema SOLUSOL

```text
                         ┌────────────────────────┐
                         │      SOLUSOL_NET       │
                         │ (Identidad & Nodos Ed) │
                         └───────────┬────────────┘
                                     │ Resuelve Nodos y Claves Públicas
                                     ▼
┌─────────────────────┐   Firmas    ┌──────────────────────┐   Telemetría   ┌─────────────────────┐
│  Cliente / Anuncio  ├────────────>│      ADSOLUSOL       ├───────────────>│       API_SIC       │
│  (Host Soberano)    │  Ed25519    │ (Serving & Contab.)  │   Agregada     │  (Marketing Brain)  │
└─────────────────────┘             └──────────────────────┘                └─────────────────────┘
```