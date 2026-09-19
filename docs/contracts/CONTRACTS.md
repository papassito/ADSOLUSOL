# AD SOLUSOL — Contracts

**Estado:** BASELINE + CURRENT DATA SHAPES / PRE-SELLO

## Campaign

Entidad actual:

```text
Id              string (GUID textual)
TenantId        string
Name            string
Status          string
Budget          decimal
BudgetSpent     decimal
RemainingBudget derivado, no persistido
CostPerMille    decimal
CostPerClick    decimal
StartDateUtc    DateTime
EndDateUtc      DateTime
CreatedAtUtc    DateTime
```

Estados utilizados por la aplicación/documentación:

```text
SCHEDULED
ACTIVE
PAUSED
COMPLETED
```

La implementación actual de `CampaignService` crea campañas inicialmente como `PAUSED`.

## Placement

```text
Id            long
PlacementCode string
Name          string
IsEnabled     bool
CreatedAt     DateTime
UpdatedAt     DateTime
```

## Creative

```text
Id         long
Name       string
ContentUrl string
TargetUrl  string
IsEnabled  bool
CreatedAt  DateTime
UpdatedAt  DateTime
```

## AdEvent

```text
Id            string
EventId       string
CampaignId    string
CreativeId    string
PlacementId   string
PlacementCode string
TenantId      string
EventType     string
Cost          decimal
TimestampUtc  DateTime
OccurredAt    DateTime
ReceivedAt    DateTime
IPAddress     string
UserAgent     string
```

`EventId` tiene unicidad en el modelo de base de datos.

## CampaignMetrics

```text
CampaignId   string
Impressions  int
Clicks       int
Ctr          double
Budget       decimal
BudgetSpent  decimal
```

## AssignmentRequest

```text
CampaignId string
EntityId   long
```

Se utiliza tanto para asociación de placement como de creative.

## Dinero

Presupuesto, gasto, CPM, CPC y costo del evento usan `decimal` en el dominio actual.

## Identidad de Node

Una firma Ed25519 válida demuestra procedencia criptográfica bajo el verificador implementado. No demuestra autorización ni tenant. La resolución y autorización deben ser separadas:

```text
Authentication != Authorization
NodeId != TenantId
```

## Contratos futuros

Eventos de ORCHESTA, disponibilidad, IA y otras integraciones permanecen como contratos de diseño hasta que exista implementación y evidencia verificable. No se consideran runtime actual por aparecer en documentación.
