# Verificación del sitio anunciado

Al crear un creativo con TargetUrl HTTPS, el backend registra un token aleatorio de 256 bits por propietario y dominio exacto. Las siguientes creaciones sobre ese dominio reutilizan el mismo código.

En Estudio de Creativos, el operador obtiene la etiqueta:
```html
<meta name="adsolusol-verification" content="TOKEN_GENERADO_POR_EL_SERVIDOR">
```
Se coloca dentro de head en el index.html, index.php o plantilla principal que sirve la raíz pública. No se pega el marcador anterior: se copia la etiqueta real del panel.

## Flujo
1. Guardar el creativo.
2. Copiar el código desde su tarjeta o desde la URL seleccionada en el estudio.
3. Publicar la etiqueta en la raíz HTTPS del dominio exacto.
4. Pulsar Verificar sitio.
5. El backend recupera HTML, compara etiqueta/token y persiste VERIFIED o FAILED y fecha.
6. Volver a comprobar después de cambios: una etiqueta retirada invalida la verificación al comprobarse de nuevo.

www y el dominio raíz son verificaciones distintas. El verificador no sigue redirecciones; se debe usar el hostname final exacto. El path/query de una landing no cambia el código del dominio.

## API autenticada
- GET /api/SiteVerifications?targetUrl=... consulta el código existente.
- POST /api/SiteVerifications con { "targetUrl": "https://example.com" } permite generar para creativos anteriores.
- POST /api/SiteVerifications/verify con el mismo cuerpo realiza la comprobación remota.
- POST /api/Creatives incluye verification en su respuesta manteniendo los campos anteriores.

Se conserva el middleware existente de sesión/firmas. El token de verificación es público, no una credencial de acceso.
La tabla SiteVerifications se crea de manera aditiva e idempotente en la misma conexión SQLite configurada. No se recrean tablas ni se borran datos. La cuenta del servicio necesita permiso CREATE TABLE en el primer uso.
Los intentos de red tienen límite de 10 segundos y 512 KB, HTTPS con certificado validado, sin cookies/proxy/redirects. El socket se conecta a una IP pública validada para impedir acceso a direcciones privadas y evitar una segunda resolución DNS.
VERIFIED demuestra presencia de la etiqueta en el momento indicado. No activa campañas, no acredita visitas o ventas, y no reemplaza el sensor SIC.

## Validación
La suite SiteVerificationTests cubre persistencia, reutilización, aislamiento, coincidencia exacta, ausencia/retirada de etiqueta, errores de red y política de destinos.
El workflow Site verification checks ejecuta las pruebas .NET y la comprobación/build del frontend en pull requests.
La implementación se preparó con el entorno local desconectado. Verificar los resultados de CI antes de integrar. No se ha desplegado ni instalado etiquetas en los sitios del laboratorio.
