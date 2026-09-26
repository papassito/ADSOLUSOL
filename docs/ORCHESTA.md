# AD SOLUSOL — Demarcación e Integración con ORCHESTA

**Estado:** CANÓNICO / ESPECIFICACIÓN DE LÍMITES  
**Dominio:** Orquestación y Coordinación Multimodal  

## 1. Alcance y Límites

De acuerdo con los principios rectores de `README.md` y `docs/ADSOLUSOL.md`:
- **ORCHESTA** es el motor transversal de coordinación de flujos en el ecosistema solusol.net.
- **AD SOLUSOL (ADS)** mantiene autoridad exclusiva sobre campañas, placements, creativos, serving, métricas de pauta publicitaria y débitos presupuestarios.

## 2. Puntos de Contacto Contractuales

1. **Event Dispatching:** ADS publica eventos de ciclo de vida (`CampaignActivated`, `BudgetExhausted`) para consumo de suscriptores orquestados.
2. **No Intrusión:** ORCHESTA no ejecuta mutaciones de gasto publicitario ni administra la persistencia de campañas SQLite.
3. **Zero-Synthetic:** Ningún evento de orquestación puede fabricar impresiones ni clics sintéticos.