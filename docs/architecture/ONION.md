# AD SOLUSOL — Onion Architecture

## Capas

```text
┌─────────────────────────────────────────────┐
│ Infrastructure                             │
│ HTTP / DB / Event Bus / Edge / Wails       │
│  ┌───────────────────────────────────────┐  │
│  │ Adapters                             │  │
│  │ API / Persistence / ORCHESTA / SIC   │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │ Application                    │  │  │
│  │  │ Campaign / Validate / Delivery │  │  │
│  │  │  ┌───────────────────────────┐  │  │  │
│  │  │  │ Domain Core               │  │  │  │
│  │  │  │ Campaign/Event/Budget     │  │  │  │
│  │  │  └───────────────────────────┘  │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Regla de dependencia

Las dependencias apuntan hacia el dominio.

El dominio no conoce:

- Express;
- PHP;
- MariaDB;
- SQLite;
- React;
- Wails;
- Cloudflare;
- ORCHESTA concreto.

Los adaptadores traducen esos entornos al contrato del dominio.

## Beneficio

Permite migrar la implementación heredada sin cambiar la semántica de campaña, evento, métrica o presupuesto.
