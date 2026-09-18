# Evidencia de validación

**ADVERTENCIA: EVIDENCIA HISTÓRICA. Este documento describe el estado de una versión anterior del producto. No debe ser utilizado como referencia para el estado actual.**

---

Validación local de la base de código en una fecha anterior:

- SDK instalado: .NET 8.0.425.
- Compilación de la solución: cero errores y cero advertencias.
- **17 comprobaciones de regresión definidas** (en el código actual) que cubren: estados, persistencia, precisión decimal, aislamiento de tenant, etc.
- Prueba HTTP aprobada: autenticación, validación de entrada, creación, lectura después
  de reiniciar el proceso, 404 para campañas inexistentes y 503 para generación sin SIC.
- Las pruebas usan datos identificados como pruebas, en bases temporales aisladas.

**Conclusión Histórica:** La evidencia demostraba un estado funcional de una versión anterior. El estado actual debe ser verificado con una nueva ejecución de las pruebas y auditorías.
