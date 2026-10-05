# Inventario del departamento de auditoría

La entrada canónica es `audit_all_project.ps1`. La Suite Master ejecuta los auditores en fases y consolida el código de salida de cada uno.

## Cobertura activa

| Área | Auditor | Lenguaje o superficie | Función | Master |
|---|---|---|---|---|
| Codificación | `audit-unicode.ps1` | Todos los archivos fuente | BOM, Unicode inválido, nulos y reemplazos | Sí |
| Codificación | `audit-mojibake.ps1` | UTF-8 y texto | Doble codificación y corrupción | Sí |
| Codificación | `radiografia_codigo.ps1` | C#, TS, TSX, JSON, MD, PS1 | Diagnóstico por archivo y línea; reparación opcional | Sí |
| Diagnóstico | `Verificar-Errores.ps1` | Proyecto completo | Errores, stubs y síntomas de implementación incompleta | Sí |
| Arquitectura | `audit-diseno.ps1` | C# / Onion | Capas, acoplamiento, SRP y asincronía | Sí |
| Dominio | `audit-dominio.ps1` | C# / Domain | Invariantes, dinero, estados y excepciones | Sí |
| Campañas | `audit-campanas.ps1` | Campaign API y servicios | Creación, estados, tenant, presupuesto y asociaciones | Sí |
| Contratos | `audit-contratos.ps1` | Docs, C#, API | Paridad entre contratos y runtime | Sí |
| Finanzas | `audit-finanzas.ps1` | C# / ledger | CPM, CPC, decimal, débito y sobregiro | Sí |
| Lógica | `audit-logica.ps1` | C# / motor | Ranking, pacing, selección y reglas | Sí |
| Funcionalidad | `audit-funcionalidad.ps1` | C# / API | Casos de uso, serving, eventos y regresiones | Sí |
| Persistencia | `audit-basededatos.ps1` | EF Core / SQLite | DbSets, índices, transacciones y aislamiento | Sí |
| Estructura | `audit-tree.ps1` | Árbol del repositorio | Topología, higiene y duplicados | Sí |
| Métrica | `CALIFICADOR_MODULOS.ps1` | C#, TS, TSX, JS | Perfil cuantitativo por módulo | Sí |
| Seguridad | `audit-seguridad.ps1` | C# / API | Firma, replay, secretos e inyección | Sí |
| Integridad | `autopsia_integridad.ps1` | Docs, tests, dependencias | Sellos, Onion, arquitectura y NuGet | Sí |
| Telemetría | `audit-telemetria.ps1` | Eventos y SIC | Ingesta, deduplicación, outbox, reintentos y dispatcher | Sí |
| Tecnología | `audit-tecnologia.ps1` | .NET, C#, React, Vite, MAUI | Versiones, stack y dependencias | Sí |
| Compilación | `audit-compilacion.ps1` | .NET 8 / C# | Restore, build y diagnósticos | Sí |
| Motor | `audit-motor.ps1` | C# / Motor | Engine, strategies y deuda técnica | Sí |
| Orquestación | `audit-orquestador.ps1` | C# / Orchestrator | Coordinadores, flujos y acoplamientos | Sí |
| Concurrencia | `audit-concurrencia.ps1` | C# / runtime | Atomicidad, carreras y thread-safety | Sí |
| Carga | `test-stress.ps1` | Runtime .NET / HTTP | Estrés y concurrencia masiva | Sí |
| Forense | `radiologico_forense.ps1` | C# y archivos | Archivo, línea, columna y causa | Sí |
| Quality gate | `junta_medica.ps1` | Proyecto completo | Gate compuesto de compilación, seguridad y regresión | Sí |
| Vivo | `audit-live.ps1` | Git, build y runtime | Estado actual integrado | Sí |
| Web | `audit-web.ps1` | React / TypeScript / Vite | Entradas, estructura, deuda y tamaño | Sí |

## Herramientas fuera de la Suite Master

| Archivo | Motivo |
|---|---|
| `Calificar-Proyecto.ps1` | Herramienta histórica de calificación universal; conservar para ejecución manual hasta migrar sus reglas a auditores especializados. |
| `push.ps1` | Operación Git; no es auditoría. |
| `update_github.ps1` | Operación GitHub; no es auditoría. |
| `reparar-sellos.ps1` | Reparación mutante de sellos; no debe ejecutarse como auditoría de solo lectura. |
| `smoke-test.ps1` | Prueba contra un servicio desplegado; requiere un runtime externo. |

## Criterio de cero tolerancia

Un auditor debe cumplir estas reglas:

1. Resolver la raíz por `ADSOLUSOL.sln`.
2. No modificar archivos durante una auditoría.
3. Emitir códigos identificables por regla.
4. Terminar con código distinto de cero ante una infracción crítica.
5. No ocultar excepciones, errores de compilación ni archivos faltantes.
6. Declarar explícitamente cuando una prueba no puede ejecutarse.
7. Mantenerse limitado al lenguaje y superficie indicados.

La Suite Master valida además que todos los archivos `audit-*.ps1` estén registrados en su pipeline. Si aparece uno nuevo sin integrar, se considera una falta del departamento de auditoría.
