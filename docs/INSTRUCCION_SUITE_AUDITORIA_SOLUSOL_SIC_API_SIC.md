# Instrucción de implementación de la Suite de Auditoría

## Alcance

Implementar el mismo modelo de auditoría en los repositorios:

- SOLUSOL_SIC
- API_SIC

Cada repositorio conserva su propio informe, inventario y estado de calidad. La suite debe auditar el lenguaje y la arquitectura reales de cada repositorio.

## Árbol requerido

~~~text
<repositorio>/
├── scripts/
│   └── audit/
│       ├── audit_all_project.ps1
│       ├── audit-unicode.ps1
│       ├── audit-mojibake.ps1
│       ├── audit-formato.ps1
│       ├── audit-tree.ps1
│       ├── audit-seguridad.ps1
│       ├── audit-contratos.ps1
│       ├── audit-basededatos.ps1
│       ├── audit-logica.ps1
│       ├── audit-funcionalidad.ps1
│       ├── audit-telemetria.ps1
│       ├── audit-concurrencia.ps1
│       ├── audit-tecnologia.ps1
│       ├── audit-compilacion.ps1
│       ├── audit-web.ps1
│       ├── Detect-AuditFalsePositives.ps1
│       └── Detect-AuditFalseNegatives.ps1
├── _audit/
│   ├── audit_master_latest.txt
│   ├── audit_false_positives.txt
│   ├── audit_false_negatives.txt
│   ├── duplicates.txt
│   └── project_junk.txt
└── docs/
    └── INVENTARIO_AUDITORIA.md
~~~

Los auditores que no correspondan deben marcarse como SKIP JUSTIFICADO con razón técnica. No deben desaparecer silenciosamente.

## Instalación

Desde la raíz de cada repositorio:

~~~powershell
New-Item -ItemType Directory -Force .\scripts\audit, .\_audit | Out-Null
Copy-Item ..\ADSOLUSOL\scripts\audit\*.ps1 .\scripts\audit\ -Force
~~~

Cada auditor debe aceptar -Root y tener un valor predeterminado seguro:

~~~powershell
param([string]$Root = ".")
if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Get-Location).Path
}
~~~

## Adaptación por repositorio

### SOLUSOL_SIC

Auditar recepción de mensajes, idempotencia por MessageId, persistencia, estados PENDING, PROCESSED, FAILED y RETRYING, backoff, contratos de telemetría, firmas, deduplicación, endpoints, índices, transacciones y recuperación tras caída.

### API_SIC

Auditar endpoints, DTOs, validación, autenticación, autorización, aislamiento por tenant, códigos HTTP, rate limiting, logging, correlación, health checks, OpenAPI, CORS, headers de seguridad, pruebas de integración y compatibilidad con SOLUSOL_SIC.

No se deben copiar reglas de .NET, React o SQLite si el repositorio utiliza otra plataforma.

## Suite Master

audit_all_project.ps1 debe resolver la raíz, ejecutar fases, registrar auditores, detectar auditores no registrados, continuar después de fallos, guardar TXT, actualizar audit_master_latest.txt, informar PASS/WARN/FAIL y devolver código 1 ante cualquier FAIL.

~~~powershell
.\scripts\audit\audit_all_project.ps1 -ReportPath ".\_audit\audit_master_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
.\Detect-AuditFalsePositives.ps1
.\Detect-AuditFalseNegatives.ps1
~~~

## Cero tolerancia

Debe producir FAIL ante errores de compilación o parser, endpoints rotos, contratos incompatibles, falta de tenant isolation, duplicación de MessageId, eventos sin persistencia, retry sin backoff, secretos, corrupción de codificación, proyectos fuera de la solución, pruebas críticas ausentes, auditores no registrados o imposibilidad de escribir el informe.

WARN se reserva para recomendaciones que no afecten integridad, seguridad, compilación, datos o compatibilidad.

## Certificación

~~~powershell
dotnet restore
dotnet build -c Release
.\scripts\audit\audit_all_project.ps1
.\Detect-AuditFalsePositives.ps1
.\Detect-AuditFalseNegatives.ps1
~~~

La integración se aprueba únicamente cuando todos los auditores inventariados se ejecutan, FAIL = 0, WARN = 0, no quedan falsos positivos o negativos sin revisar y se genera el informe TXT.
