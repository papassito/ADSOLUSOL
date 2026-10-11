# Changelog — ADSOLUSOL

Todas las modificaciones notables de este proyecto se registran en este documento bajo el formato canónico Keep a Changelog.

---

## [2027-Prealfa] — 2026-10-10
### Added
- Institucionalización del paquete documental Nivel 5: `MANIFEST.md`, `ARCHITECTURE.md`, `COMPONENTS.md`, `SECURITY.md`, `API.md`, `DATABASE.md` y `DEPLOYMENT.md`.
- Establecimiento de dominios de producción: `api.solusol.net` para servicios API y `adsolusol.solusol.net` para el portal y panel de control.
- Eliminación y prohibición de dependencias y rastreadores de redes publicitarias externas.

## [2027-Prealfa] — 2026-10-10
### Added
- Institucionalización del paquete documental Nivel 5: `MANIFEST.md`, `ARCHITECTURE.md`, `COMPONENTS.md`, `SECURITY.md`, `API.md`, `DATABASE.md` y `DEPLOYMENT.md`.
- Especificación de contratos Ed25519 con encabezados `X-Solusol-*` y aislamiento multi-tenant.
- Matriz de responsabilidades de componentes para evitar mezcla de roles con SEO, ERP o sistemas fiscales.

---

## [2026-09-24] — Estabilización de Frontend y Persistencia
### Added
- Configuración canónica de Vite con soporte para rutas mapeadas en Windows (`usePolling: true`).
- Proxy reverso en frontend hacia backend Kestrel en puerto 5000.
### Fixed
- Resolución del error `TS6310` en referencias de TypeScript (`tsconfig.node.json`).
- Inicialización automática de tablas en SQLite en entorno de desarrollo.

---

## [2026-09-19] — Blindaje de Seguridad e Integración SIC
### Added
- Registro y cableado del `SignatureVerificationMiddleware` en `Program.cs`.
- Integración real asíncrona mediante `HttpClient` en `MarketingBrainClient` eliminando mocks de prueba.
- Verificación de salud integrada en `/api/health` consultando la base de datos y `{SicBaseUrl}/health`.

---

## [2026-09-18] — Corrección de Transacciones y Suite de Regresiones
### Added
- Suite de regresión in-process con 20 comprobaciones de negocio (`ADSOLUSOL.RegressionTests`).
- Prueba de estrés multihilo que valida la preservación del techo presupuestario ante colisiones masivas concurrentes.
### Fixed
- Pérdida de persistencia en `AssignmentRepository` y `AdEventRepository` mediante `SaveChangesAsync`.
- Implementación del método de débito atómico condicional (`BudgetSpent + Cost <= Budget`) en `BudgetService`.
- Corrección del método de selección de creativos `SelectAdForPlacement` en `ServeController`.

---

## [2026-09-10] — Creación del Repositorio
### Added
- Estructura Onion Architecture (.NET 8): Domain, Application, Infrastructure, Presentation.Api, Presentation.Desktop (MAUI Blazor).
- Modelos base de dominio: `Campaign`, `Creative`, `Placement`, `AdEvent`.
- Endpoints iniciales de serving, campañas y métricas.
```

```nginx
server {
    listen 80;
    server_name ads.solusol.net;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Bypass de caché estricto para subastas y telemetría
        proxy_no_cache 1;
    }
}
```