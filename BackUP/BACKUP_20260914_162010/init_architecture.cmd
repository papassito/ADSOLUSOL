@echo off
setlocal EnableDelayedExpansion
echo [INFO] Ejecutando el inicializador de arquitectura ADSOLUSOL...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init_architecture.ps1"
echo.
pause