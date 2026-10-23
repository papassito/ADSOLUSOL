# Peritaje de Datos Sintéticos y Elementos Demo (Auditoría Anti-Mentiras)

**Objetivo:** Erradicación total de datos inventados, mocks, simuladores y valores hardcodeados en el portal de producción (`adsolusol.solusol.net`).

---

## Inventario de Brechas Detectadas

### 1. `src/data/adEngineData.ts`
- **Línea:** 286
- **Fragmento:**
  ```typescript
  export const MOCK_BIDDERS = {
    dv360: { name: 'Google DV360', dsp: 'DV360', bid: 4.80, ... },
    tradedesk: { name: 'The Trade Desk', dsp: 'The Trade Desk', bid: 5.40, ... },
    ...
  };
  ```
- **Impacto:** Simula pujas de DSPs externas en componentes de subasta visual.
- **Acción:** Purgar del bundle de producción. Si no hay postores reales vía API o el endpoint no devuelve pujas, la UI debe desplegar `NO_DATA` o `LISTENING`.

### 2. `docs/INTERFAZ_2027.md`
- **Línea:** Párrafo 3
- **Fragmento:**
  ```text
  La subasta, los débitos, las firmas Ed25519, la telemetría SIC, el bloqueo de términos, los datos iniciales, las métricas completadas y la proyección son simulados...
  ```
- **Impacto:** Documentación declarando que la UI opera con datos supuestos y simulados en lugar de reflejar el backend .NET Kestrel.
- **Acción:** Reescribir para prohibir explícitamente el modo simulado en el build de producción.

### 3. `src/ADSOLUSOL.Presentation.Web/src/api.ts`
- **Línea:** 127
- **Fragmento:**
  ```typescript
  baseUrl: API_BASE || "same-origin"
  ```
- **Impacto:** Posible resolución ambigua de backend si `VITE_API_BASE_URL` no está definido en tiempo de compilación.
- **Acción:** Fallar de forma explícita (*fail-fast*) si no hay conexión con Kestrel, sin caer en generadores de datos ficticios en memoria.

---

## Regla Operativa de Aceptación Comercial

Para que el sistema sea considerado **aprobado para clientes**:
1. Cero ocurrencias de cadenas `mock`, `demo`, `simulat*`, `fake` en el bundle publicado (`dist/assets/*.js`).
2. Prohibido mostrar métricas distintas de cero cuando una campaña no registra impresiones o clics en base de datos (`REQ-MET-002`).
3. Ante caída de red o error de API, mostrar honestamente `DISCONNECTED` o `UNAVAILABLE`. Prohibido inventar gráficos o proyecciones.