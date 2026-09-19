# Estructura de ADSOLUSOL

**Estado:** CURRENT REPOSITORY STRUCTURE / PRE-SELLO

```text
ADSOLUSOL/
├── ADSOLUSOL.sln
├── README.md
├── REQUIREMENTS.md
├── ROADMAP.md
├── MAP.md
├── COMPONENTS.md
├── docs/
│   ├── architecture/
│   ├── business/
│   ├── contracts/
│   ├── decisions/
│   ├── evidence/
│   ├── integration/
│   ├── operations/
│   ├── phases/
│   └── security/
├── src/
│   ├── ADSOLUSOL.Domain/
│   ├── ADSOLUSOL.Application/
│   ├── ADSOLUSOL.Infrastructure/
│   ├── ADSOLUSOL.Motor/
│   ├── ADSOLUSOL.Orchestrator/
│   ├── ADSOLUSOL.Presentation.Api/
│   ├── ADSOLUSOL.Presentation.Cmd/
│   └── ADSOLUSOL.Presentation.Web/
├── tests/
│   └── ADSOLUSOL.RegressionTests/
└── _audit/
```

## Observaciones

- `ADSOLUSOL.Presentation.Web` contiene React 18 + TypeScript + Vite.
- La UI todavía no está integrada a `wwwroot`/publish en el código observado.
- `src/ADSOLUSOL.sln` existe vacío y no es la solución canónica; la solución válida está en la raíz.
- `tests/ADSOLUSOL.RegressionTests/.env.example` permanece como artefacto heredado y debe revisarse antes del sellado final.
- existen varios `.gitkeep` y archivos stub/vacíos; su mera existencia no equivale a componente implementado.

## Base de datos

Development configura:

```text
Data Source=App_Data/adsolusol.db
```

`Program.cs` usa `EnsureCreated()`. Production todavía no define `DefaultConnection` en `appsettings.json` y no existe estrategia cerrada de migraciones/upgrades.

## Regresiones

La suite ejecutable contiene 17 comprobaciones numeradas de negocio. Estado correcto en documentación:

```text
17 TESTS DEFINED
```

Solo una ejecución reciente con exit code 0 autoriza:

```text
17/17 VERIFIED PASS
```

## Documentación duplicada

El repositorio conserva copias idénticas en raíz, `docs/` y subcarpetas temáticas. Para el sellado se permite mantenerlas únicamente si permanecen sincronizadas byte a byte o se define una ruta canónica y las otras se convierten en referencias. No se deben mantener duplicados divergentes.
