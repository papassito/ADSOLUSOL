# AD SOLUSOL — Requirements

**Estado:** NORMATIVE BASELINE / no implica implementación actual

**PRODUCT:** AD SOLUSOL (ADS)  
**DOMAIN:** Advertising & Growth  
**PLATFORM:** SOLUSOL Intelligence Center (SIC)  
**COMMERCIAL HEAD:** KLIK Soft PRO  
**SOFTWARE DIRECTION:** solusol.net  
**SUPPORT:** CM Soluciones  


## 1. Campañas

- **REQ-ADS-001:** cada campaña debe tener identificador único.
- **REQ-ADS-002:** debe existir un anunciante identificable.
- **REQ-ADS-003:** toda campaña debe declarar placement, vigencia, presupuesto y modelo de precio.
- **REQ-ADS-004:** estados canónicos: `ACTIVE`, `PAUSED`, `SCHEDULED`, `COMPLETED`.
- **REQ-ADS-005:** una campaña fuera de vigencia no puede comportarse como activa.
- **REQ-ADS-006:** el frontend no es autoridad de gasto.

## 2. Métricas

- **REQ-MET-001:** CTR deriva de clics verificados e impresiones verificadas.
- **REQ-MET-002:** sin impresiones verificables no se inventa CTR.
- **REQ-MET-003:** CPM y CPC se calculan en servidor.
- **REQ-MET-004:** eventos duplicados no incrementan métricas.
- **REQ-MET-005:** métricas publicitarias y telemetría operacional son dominios distintos.

## 3. Presupuesto

- **REQ-BUD-001:** CPM consume `rate / 1000` por impresión aceptada.
- **REQ-BUD-002:** CPC consume `rate` por clic aceptado.
- **REQ-BUD-003:** evento y débito deben ser idempotentes.
- **REQ-BUD-004:** el gasto no debe superar el presupuesto por condiciones de carrera.
- **REQ-BUD-005:** dinero persistente requiere representación decimal exacta o unidad entera menor.

## 4. Seguridad

- **REQ-SEC-001:** target URLs y assets deben validarse.
- **REQ-SEC-002:** creativos no pueden ejecutar código arbitrario de terceros.
- **REQ-SEC-003:** CSP debe proteger las superficies publicitarias.
- **REQ-SEC-004:** endpoints de escritura deben usar controles de autenticidad, autorización y rate limiting.
- **REQ-SEC-005:** cabeceras de IP de proxy solo son confiables desde proxies autorizados.
- **REQ-SEC-006:** credenciales y secretos no deben exponerse al cliente.

## 5. Zero-Synthetic

- **REQ-DATA-001:** prohibido fabricar clics, impresiones, visitas, conversiones o gasto.
- **REQ-DATA-002:** distinguir `AVAILABLE`, `DISCONNECTED`, `NO_DATA`, `UNAVAILABLE`, `UNVERIFIED`, `UNDETERMINED`.
- **REQ-DATA-003:** `DISCONNECTED` no equivale a cero.
- **REQ-DATA-004:** `NO_DATA` no equivale a bajo rendimiento.
- **REQ-DATA-005:** valores simulados de Core Web Vitals no pueden presentarse como mediciones reales.

## 6. SEO / SUPER SEO

- **REQ-SEO-001:** SEO permanece separado de ADS.
- **REQ-SEO-002:** el crawler debe aplicar controles Anti-SSRF antes de fetch.
- **REQ-SEO-003:** SEO puede producir señales para GROWTH sin convertirlas en métricas ADS.
- **REQ-SEO-004:** SUPER SEO puede correlacionar señales, pero no altera los registros publicitarios fuente.

## 7. Multi-tenant

- **REQ-TEN-001:** toda campaña debe poder vincularse a `tenant_id`.
- **REQ-TEN-002:** la persistencia y consulta deben respetar aislamiento por tenant.
- **REQ-TEN-003:** ninguna operación tenant-scoped debe aceptar, consultar, mutar o agregar datos de otro tenant.

## 8. Integración

- **REQ-INT-001:** ADS publica eventos de campaña y publicidad mediante contratos definidos.
- **REQ-INT-002:** ORCHESTA coordina eventos sin convertirse en autoridad de presupuesto.
- **REQ-INT-003:** SIC consume señales y presenta estado.
- **REQ-INT-004:** identidad criptográfica de Nodes es gobernada por CORE; ADS/SIC solo consume verificación autorizada.

## 9. API

- **REQ-API-001:** rutas dinámicas no deben ser cacheadas de manera que omitan o dupliquen eventos.
- **REQ-API-002:** respuestas deben diferenciar `accepted`, `duplicate`, `rejected`, `unavailable`.
- **REQ-API-003:** contadores enviados por cliente nunca son autoridad.
- **REQ-API-004:** el endpoint de salud no debe fingir estado saludable ante fallos reales.
