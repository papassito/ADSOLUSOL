@echo off
rem ============================================================================
rem  ADSOLUSOL :: AUTOPSIA DE INTEGRIDAD - Lanzador de Conveniencia
rem  Ejecuta el script de autopsia con la política de ejecución correcta
rem  para evitar bloqueos de seguridad en sistemas estándar.
rem ============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\autopsia_integridad.ps1" %*