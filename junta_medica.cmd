@echo off
rem ============================================================================
rem  ADSOLUSOL :: JUNTA MEDICA - Lanzador de Conveniencia
rem  Ejecuta el script forense de PowerShell con la política de ejecución
rem  correcta para evitar bloqueos de seguridad en sistemas estándar.
rem ============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\junta_medica.ps1" %*