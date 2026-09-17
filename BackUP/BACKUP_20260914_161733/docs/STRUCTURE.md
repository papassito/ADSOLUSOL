# Estructura de ADSOLUSOL

```text
ADSOLUSOL/
|-- ADSOLUSOL.sln
|-- README.md
|-- .gitignore
|-- src/
|   |-- ADSOLUSOL.Domain/
|   |-- ADSOLUSOL.Application/
|   |-- ADSOLUSOL.Infrastructure/
|   |-- ADSOLUSOL.Motor/
|   |-- ADSOLUSOL.Orchestrator/
|   |-- ADSOLUSOL.Presentation.Api/
|   `-- ADSOLUSOL.Presentation.Cmd/
|-- docs/
|   |-- LIBRARY.md, REQUIREMENTS.md, ROADMAP.md, STRUCTURE.md, MANIFEST.md
|   |-- architecture/
|   |-- business/
|   |-- contracts/
|   |-- decisions/
|   |-- evidence/
|   |-- integration/
|   |-- operations/
|   |-- phases/
|   `-- security/
`-- scripts/
    |-- check_structure.ps1
    `-- update_manifest.ps1
```

## Reglas

- Una solución en la raíz; proyectos de producto en `src/` y comprobaciones de regresión en `tests/`.
- Documentación en `docs/`, clasificada por tema e indexada en [LIBRARY.md](LIBRARY.md).
- No crear copias de documentos en la raíz, carpetas de respaldo ni archivos con sufijos de copia.
- Crear carpetas solo cuando haya contenido; no se requieren `.gitkeep`.
- `bin/` y `obj/` son salidas generadas por .NET, excluidas de Git.
- Los archivos `.csproj` pueden coincidir en contenido: pertenecen a ensamblados distintos y no son duplicados eliminables.
- Cada aplicación conserva su propio `Program.cs` y `appsettings.json`.
- Los scripts resuelven la raíz desde su ubicación, independientemente del directorio actual.
- Tras editar documentación, actualizar su inventario SHA-256 con `scripts/update_manifest.ps1`.

Se retiraron los inicializadores ya ejecutados: contenían copias del código y de la
estructura documental. Los documentos completos sustituyen a los marcadores de texto.
El respaldo previo se conserva fuera del proyecto.

## Comprobaciones de regresión

El proyecto tests/ADSOLUSOL.RegressionTests es un ejecutable sin dependencias de pruebas externas. Se ejecuta con: dotnet run --project tests/ADSOLUSOL.RegressionTests. Requiere el SDK de .NET 8. Las 34 comprobaciones y la prueba HTTP pasaron en este equipo.


La base SQLite se guarda en App_Data/ (ignorada por Git). Los scripts dotnet.ps1 y smoke_test.ps1 permiten compilar y probar con el SDK local; las pruebas HTTP usan una base temporal aislada y comprueban la persistencia tras reiniciar la API.

