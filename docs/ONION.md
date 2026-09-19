# AD SOLUSOL — Onion Architecture

**Estado:** ARCHITECTURE BASELINE / implementación parcial

## Capas observadas

```text
Presentation
├── ADSOLUSOL.Presentation.Api      ASP.NET Core
├── ADSOLUSOL.Presentation.Web      React / TypeScript / Vite
└── ADSOLUSOL.Presentation.Cmd
        ↓
Application
├── CampaignService
├── AdServingService
├── EventProcessingService
├── MetricsService
└── BudgetService
        ↓
Domain
├── Entities
├── DTOs / Enums
└── Interfaces
        ↑
Infrastructure
├── SQLite / EF Core / Dapper
├── Repositories
├── CoreSignatureVerifier
└── MarketingBrainClient
```

## Regla de dependencia

El dominio no debe depender de detalles de HTTP, SQLite, Vite, proxy, SIC u otros adaptadores concretos.

## Estado actual

La solución está separada en proyectos `Domain`, `Application`, `Infrastructure`, `Motor`, `Orchestrator`, `Presentation.Api`, `Presentation.Cmd` y una UI Vite/React.

`Motor` y `Orchestrator` contienen todavía estructuras mínimas/stubs en varias áreas y no deben presentarse como motores completamente operativos únicamente por existir como proyectos.

## Tecnologías heredadas

Referencias históricas a Express, PHP, MariaDB o Wails no describen el stack actual de ADSOLUSOL. El stack observado hoy es .NET 8 + React/Vite + SQLite.
