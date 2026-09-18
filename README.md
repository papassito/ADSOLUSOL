# AD SOLUSOL — Advertising & Growth Engine

**Status:** OPERATIVE VERIFIED  
**Product:** AD SOLUSOL (ADS)  
**Platform:** SOLUSOL Center Intelligence (SIC)  
**Commercial Head:** KLIK Soft PRO  
**Software Direction:** solusol.net  
**Support:** CM Soluciones

## Propósito
AD SOLUSOL (ADS) es el subsistema nativo de publicidad, monetización y analítica publicitaria del ecosistema solusol.net / SOLUSOL Center Intelligence (SIC). Administra campañas, placements, creativos, impresiones, clics, CTR, CPM, CPC, presupuesto y telemetría first-party.

## Dentro de ADS
- Campaign management.
- Placement inventory.
- Creative delivery.
- Verified impressions and clicks.
- CTR / CPM / CPC.
- Budget consumption.
- Advertising telemetry.
- Privacy-first operation.
- Integración con SIC/GROWTH.

## Fuera de ADS
- SEO/SUPER SEO.
- Growth Score global.
- CORE/WAF/DDoS como dominio primario.
- Motores fiscales, contables o laborales.
- Tracking publicitario de terceros como dependencia funcional.

## Principios
### Server-authoritative accounting
El servidor es autoridad para métricas facturables y gasto.

### Zero-Synthetic Advertising Data
```text
DISCONNECTED != 0 CLICKS
DISCONNECTED != 0 IMPRESSIONS
NO_DATA != ZERO PERFORMANCE
UNVERIFIED != VALID TRAFFIC
```

### Privacy-first
ADS funciona con telemetría first-party mínima.

## API base
```text
GET  /api/marketing/adsolusol
POST /api/marketing/adsolusol/campaigns
POST /api/marketing/adsolusol/campaigns/:id/toggle
POST /api/marketing/adsolusol/campaigns/:id/click
POST /api/marketing/adsolusol/campaigns/:id/impression
```

La biblioteca técnica completa está indexada en [docs/LIBRARY.md](docs/LIBRARY.md).

## Estado de implementación

La solución .NET 8 está operativa y verificada. La API gestiona campañas y eventos de clics/impresiones con persistencia en SQLite. Implementa un mecanismo de autenticación basado en firmas digitales (Ed25519), con protección anti-replay y de idempotencia a nivel de negocio.

La integración con el SIC para la generación de contenido dinámico sigue pendiente y los endpoints relacionados devuelven indisponibilidad explícita.

## Desarrollo

El proyecto utiliza el SDK de .NET 8.

```powershell
# Construir la solución
dotnet build ADSOLUSOL.sln

# Ejecutar las pruebas de regresión (es un ejecutable)
dotnet run --project tests/ADSOLUSOL.RegressionTests/ADSOLUSOL.RegressionTests.csproj
```

Las regresiones son un ejecutable de comprobación; no usan dotnet test.

## Ejecutar la API local

Configurar una clave privada de desarrollo antes de arrancar:

```powershell
$env:Api__Key = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
$env:Api__TenantId = 'local'
.\Start-Dev.ps1
```

Enviar esa clave en la cabecera X-Api-Key de las solicitudes. No guardarla en el código.
La API escucha por defecto en http://127.0.0.1:5080. Sin clave configurada responde 503;
una clave incorrecta responde 401. Es una protección local inicial, pendiente de sustituir
por la identidad y autorización del SIC antes de un despliegue compartido.

- POST /api/marketing/adsolusol/campaigns acepta un JSON con name y budget positivo.
- GET /api/marketing/adsolusol/campaigns lista las campañas del tenant configurado en el servidor.
- GET /api/marketing/adsolusol/campaigns/{id} consulta una campaña.
- POST /api/marketing/adsolusol/campaigns/{id}/content responde 503 hasta integrar el SIC.
- GET /api/health/storage comprueba lectura y escritura de SQLite.
- GET /api/health comprueba SQLite y SIC: actualmente indica persistencia disponible y SIC no disponible.

Los datos se guardan en App_Data/campaigns.db, bajo el directorio de contenido de la API.
Storage__Path permite definir otra ruta. Las transacciones guardan el lote completo o
lo revierten; los presupuestos se almacenan como texto decimal exacto. La salud no inserta campañas ficticias.
El tenant procede de configuración del servidor, no de datos enviados por el cliente.

Consultar [la estructura](docs/STRUCTURE.md) y [la evidencia](docs/evidence/EVIDENCE.md).
