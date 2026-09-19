# AD SOLUSOL — ORCHESTA Integration

**Estado:** TARGET / PLANNED INTEGRATION

ORCHESTA coordina flujos y eventos entre módulos del ecosistema. No es autoridad de CTR, CPM, CPC ni presupuesto de ADSOLUSOL.

## Estado runtime observado

Existe el proyecto `ADSOLUSOL.Orchestrator`, pero sus clases actuales son estructuras mínimas y no constituyen evidencia de una integración ORCHESTA operacional completa.

No se debe afirmar publicación/consumo real de eventos ORCHESTA hasta disponer de implementación y prueba.

## Contrato objetivo

Cuando se implemente:

1. ADS emitirá eventos versionados y verificables;
2. ORCHESTA coordinará, no recalculará métricas ADS;
3. autenticación y autorización permanecerán separadas;
4. una caída de ORCHESTA no autorizará datos sintéticos.
