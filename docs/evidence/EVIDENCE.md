# Evidencia de validación

**STATUS: HISTORICAL EVIDENCE / SUPERSEDED FOR CURRENT-STATE CLAIMS**

Este archivo conserva evidencia de una etapa anterior. Las afirmaciones siguientes deben leerse en su contexto histórico y no certifican el runtime actual. No se reescriben los resultados históricos para hacerlos coincidir con la suite actual.

---

Validación local de la base inicial:

- SDK instalado: .NET 8.0.425.
- Compilación de la solución: cero errores y cero advertencias.
- 34 comprobaciones de regresión aprobadas: estados, persistencia entre contextos,
  precisión decimal, consultas por tenant, rollback de lotes, concurrencia, cancelación,
  salud de almacenamiento inaccesible y ausencia explícita de integración SIC.
- Prueba HTTP aprobada: autenticación, validación de entrada, creación, lectura después
  de reiniciar el proceso, 404 para campañas inexistentes y 503 para generación sin SIC.
- Las pruebas usan datos identificados como pruebas, en bases temporales aisladas.

Comandos utilizados históricamente en esa etapa:

```powershell
.\scripts\dotnet.ps1 build ADSOLUSOL.sln
.\scripts\dotnet.ps1 run --project tests/ADSOLUSOL.RegressionTests
.\scripts\smoke_test.ps1
.\scripts\check_structure.ps1
```

Estas rutas pertenecen al layout histórico documentado en esa validación y no implican que dichos scripts existan en la estructura actual del repositorio.

Pendiente: contrato y conexión al SIC, autenticación integrada, modelo publicitario
completo, flujo de anuncios, métricas y presupuesto. Esta evidencia no certifica
el sistema publicitario completo ni una integración externa todavía inexistente.

---

## Nota de estado actual

La suite actual del repositorio contiene **17 comprobaciones numeradas de negocio**. Este dato no reemplaza ni altera las 34 comprobaciones históricas registradas arriba. Para una certificación actual deben ejecutarse build, regresiones, smoke/E2E y auditoría sobre el código vigente.
