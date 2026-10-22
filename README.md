# ADSOLUSOL 2027

Motor soberano de publicidad y monetización del ecosistema SOLUSOL.

**Estado:** PREALFA / LABORATORIO — PRE-SELLO NIVEL 5  
**Propietario:** KlikSoft  
**Dirección de software:** solusol.net  
**Soporte:** CM Soluciones  

---

## 1. ¿Qué es ADSOLUSOL?

ADSOLUSOL (ADS) es la plataforma publicitaria soberana (First-Party Ad Server) diseñada para gestionar campañas, servir creativos verificados y liquidar débitos presupuestarios de forma atómica y auditable sin intermediarios.

## 2. ¿Para qué existe?

Existe para proporcionar total soberanía e independencia publicitaria frente a redes externas y plataformas intermediarias centralizadas, garantizando que las audiencias, los creativos, las impresiones y la facturación pertenezcan exclusivamente al ecosistema de la red.

## 3. ¿Qué problema resuelve?

1. **Fraude y métricas sintéticas:** Elimina el inventario inflado y las conversiones simuladas. Toda métrica proviene de eventos firmados con deduplicación por `event_id`.
2. **Filtración de privacidad:** Elimina cookies de terceros y scripts de rastreo invasivos.
3. **Sobregiros presupuestarios concurrentes:** Implementa un ledger atómico condicional en el backend que garantiza que ninguna campaña gaste más de su límite asignado (`BudgetSpent + Cost <= Budget`).
4. **Ambigüedad de roles:** Establece fronteras estrictas: ADSOLUSOL no es un motor SEO, ni un ERP, ni un timbrador fiscal.

## Principios

- **Privacy First:** Cero rastreo biométrico o perfilado entre dominios ajenos.
- **First Party Telemetry:** La telemetría se recolecta directamente entre el visitante, el nodo y el ad server.
- **Server Authoritative Accounting:** Las liquidaciones, costos y saldos son calculados exclusivamente en backend con transacciones atómicas.
- **Zero Synthetic Metrics:** Prohibido simular métricas, clics o disponibilidad.
El servidor de demostración (`npm run dev:demo`) utiliza una simulación **determinista** (no aleatoria) del motor de subasta para fines de desarrollo, pero no genera datos falsos.

## Módulos del Sistema

1. **Campaign Engine:** Gestión del ciclo de vida de campañas (`SCHEDULED`, `ACTIVE`, `PAUSED`, `COMPLETED`), vigencia y techos de inversión.
2. **Auction & Serving Engine:** Algoritmo ponderado de entrega de creativos en base a placements normalizados y presupuesto disponible.
3. **Telemetry Engine:** Ingesta de eventos firmados (`IMPRESSION`, `CLICK`) con verificación anti-replay e idempotencia estricta.
4. **Analytics Engine:** Cálculo matemático transparente de CTR, CPC y CPM sobre eventos confirmados.
5. **Dashboard & UI:** Panel de control web React 18 / Vite y aplicación nativa de escritorio .NET MAUI Blazor.

## Dominios Oficiales

- **Portal y Dashboard Web:** `https://adsolusol.solusol.net`
- **API Canónica del Sistema:** `https://api.solusol.net/api`

---

## Integraciones Ecosistémicas

### Integración con API_SIC (SOLUSOL Intelligence Center)
- **Canal Canónico:** Conexión HTTP/REST autenticada hacia `{SicBaseUrl}` (predeterminado `http://solusol.net:8080`).
- **Marketing Brain:** Transmisión de telemetría de eventos de marketing y comprobación bidireccional de salud (`/api/health` evalúa `SicEngine` y la base de datos local).

### Integración con SOLUSOL_NET
- **Identidad y Notaría:** Validación criptográfica Ed25519 mediante encabezados canónicos `X-Solusol-Node-Id`, `X-Solusol-Timestamp`, `X-Solusol-Nonce` y `X-Solusol-Signature`.
- **Aislamiento Multi-tenant:** El middleware autoritativo resuelve el `TenantId` a partir del nodo firmante y asegura que los datos de una cuenta permanezcan aislados.

---

## Cómo se ejecuta

### Requisitos Previos
- .NET 8 SDK
- Node.js 20+ y npm
- SQLite (desarrollo / borde) o PostgreSQL (persistencia consolidada)

### 1. Ejecución de la API Backend (.NET 8)
```powershell
cd src/ADSOLUSOL.Presentation.Api
dotnet restore
dotnet run --urls "http://localhost:5000"
```

`MarketingController` declara la ruta base `/api/marketing/adsolusol` exponiendo comprobaciones `/status` y `/ping`.

## Autenticación

El sistema utiliza un `SignatureVerificationMiddleware` para proteger los endpoints de la API.

- **Estado:** `IMPLEMENTED_AND_WIRED`. El middleware está conectado en `Program.cs`.
- **Mecanismo:** Verificación de firmas Ed25519, timestamp y protección anti-reenvío con nonce.
- **Rutas Públicas:** La UI de Blazor y el endpoint `/api/health` son accesibles sin firma.

## SQLite

La aplicación de escritorio MAUI crea una base de datos `adsolusol.db` en el directorio de datos de la aplicación del usuario (`AppDataDirectory`) y asegura que el esquema se cree al arrancar. La API web utiliza una cadena de conexión definida en la configuración.


## Taxonomía Canónica de GUIs y Dominios de Interfaz

El ecosistema articula sus capacidades a través de tres superficies no redundantes con responsabilidades delimitadas:

### 1. Consola de Operación Canónica (Web React 18)
- **Ruta:** `src/ADSOLUSOL.Presentation.Web`
- **Rol:** GUI Canónica de Negocio y portal principal de producción (`https://adsolusol.solusol.net`).
- **Capacidades:** Ciclo de vida de campañas, gestión de creativos HTTPS, asignación a placements normalizados, pacing presupuestario y observabilidad de telemetría en tiempo real bajo principio Zero-Synthetic.

### 2. Consola de Operación Soberana (Desktop MAUI Blazor)
- **Ruta:** `src/ADSOLUSOL.Presentation.Desktop`
- **Rol:** Nodo Soberano Edge / Local para despliegues aislados o contingencias fuera de línea.
- **Capacidades:** Operación nativa sobre SQLite local (`adsolusol.db`) sin dependencia obligatoria de red externa.

### 3. Consola de Notaría e Ingeniería (Checador / Santiago)
- **Rol:** Certificación técnica, auditoría forense y ejecución de Quality Gates Nivel 5.
- **Capacidades:** Suite runner, análisis estático, radiografía de dependencias, verificación anti-falsos positivos y detección de anomalías.

## SIC / Marketing Brain

`HealthController` verifica la conectividad de la base de datos SQLite local y comprueba la disponibilidad del motor SIC mediante `{SolusolAuthV1:SicBaseUrl}/health`, respondiendo con el contrato canónico `HealthResponse` conteniendo los checks `Database` y `SicEngine`.

La integración con **Marketing Brain (SIC) es real y está activa**. El cliente (`MarketingBrainClient`) utiliza `HttpClient` para enviar telemetría de eventos (impresiones, clics) al servicio externo y realiza comprobaciones de disponibilidad de red. Se han eliminado todas las implementaciones ficticias (mocks).

## Regresiones

`tests/ADSOLUSOL.RegressionTests/Program.cs` contiene **20 comprobaciones numeradas de negocio**. La suite verifica el ciclo completo: creación, persistencia, servicio, débitos condicionales atómicos ($0.2515), inmunidad idempotente contra ráfagas duplicadas, algoritmo de pacing ponderado por presupuesto y resistencia a ráfagas de alta concurrencia.

## Operación y Auditoría

Para auditar el estado del repositorio en tiempo real:
```powershell
powershell -File .\scripts\audit\audit-live.ps1
```
Para construir el ejecutable de producción, usa:
```powershell
powershell -File .\scripts\build\release.ps1 -Publish
```

## Estado antes de release

Pendientes de cierre técnico:
- Blindaje y pruebas de integración para el pipeline de autenticación de firmas y tenant.
- Estrategia de empaquetado y despliegue para la aplicación MAUI (e.g., MSIX).

La documentación de detalle está indexada en [`docs/LIBRARY.md`](docs/LIBRARY.md).
