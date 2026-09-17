# AD SOLUSOL — Integrity

## 1. Zero-Synthetic Advertising Data

Prohibido:

- inventar impresiones;
- inventar clics;
- inventar conversiones;
- fabricar gasto;
- sustituir desconexión por cero;
- presentar métricas simuladas como observadas.

## 2. Idempotencia

Un mismo evento lógico debe producir como máximo:

```text
1 registro aceptado
1 incremento de contador
1 débito presupuestario aplicable
```

Los reintentos no pueden producir doble gasto.

## 3. Precisión financiera

```text
CPM delta = cpm_rate / 1000
CPC delta = cpc_rate
```

Los valores monetarios autoritativos no deben depender de coma flotante binaria sin estrategia de exactitud.

## 4. Integridad de métricas

```text
verified_clicks
verified_impressions
        ↓
       CTR
```

Si el denominador no existe o no es verificable, el resultado no se fuerza a cero.

## 5. Integridad de procedencia

Cuando aplique identidad de Node:

```text
Valid Signature != Authorization
```

CORE gobierna identidad y autorización; SIC/ADS consume verificación conforme a contrato.

## 6. Conflictos heredados detectados

La documentación SEO suministrada declara valores FID/CLS fijos simulados en el backend heredado. Esos valores no deben promocionarse a métricas reales de producción bajo Zero-Synthetic.
