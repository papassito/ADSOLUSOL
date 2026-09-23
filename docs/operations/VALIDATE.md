# AD SOLUSOL — Validate

**Estado:** IMPLEMENTED / FULLY VERIFIED

## Validaciones observadas actualmente

### Campaign

- creación con `TenantId` recibido por el servicio;
- `GetAsync` y `UpdateStatusAsync` comparan `TenantId`;
- estado inicial de creación: `PAUSED`;
- fechas por defecto si no se proporcionan.

#### Máquina de Estados Estricta (C#)
Se ha implementado una validación estricta de transiciones de estado para impedir cambios arbitrarios en el endpoint `/status`:

```csharp
public enum CampaignStatus { PAUSED, ACTIVE, COMPLETED, ARCHIVED }

public class CampaignStateMachine
{
    private static readonly Dictionary<CampaignStatus, HashSet<CampaignStatus>> AllowedTransitions = 
        new()
        {
            { CampaignStatus.PAUSED, new() { CampaignStatus.ACTIVE, CampaignStatus.ARCHIVED } },
            { CampaignStatus.ACTIVE, new() { CampaignStatus.PAUSED, CampaignStatus.COMPLETED, CampaignStatus.ARCHIVED } },
            { CampaignStatus.COMPLETED, new() { CampaignStatus.ARCHIVED } },
            { CampaignStatus.ARCHIVED, new() { } } // Estado terminal, sin transiciones permitidas.
        };

    public static bool CanTransition(CampaignStatus current, CampaignStatus target)
    {
        if (current == target) return true;
        return AllowedTransitions.TryGetValue(current, out var targets) && targets.Contains(target);
    }
}
```

En el controlador de campaña se valida formalmente:
```csharp
if (!CampaignStateMachine.CanTransition(campaign.Status, targetStatus))
{
    return BadRequest($"Transición de estado inválida de {campaign.Status} a {targetStatus}");
}
```

### Serving

- placement existente;
- campaña `ACTIVE`;
- tenant coincidente en consulta de campañas elegibles;
- presupuesto restante;
- rango de fechas;
- existencia de creative asociado.
- `Placement.IsEnabled` es validado obligatoriamente en runtime.
- `Creative.IsEnabled` es validado obligatoriamente en runtime.

### Events

`EventProcessingService` valida actualmente:

- `EventId` no procesado previamente;
- campaña existente;
- campaña `ACTIVE`;
- presupuesto restante;
- tipo de evento parseable (`Click` / `Impression`);
- débito presupuestario exitoso dentro de transacción.

## Validaciones Adicionales Cerradas

### 1. Consistencia Relacional Unificada (Campaign ↔ Creative ↔ Placement)
Al registrar eventos (impresión o clic), el sistema realiza una consulta relacional atómica para asegurar la correspondencia lógica real del trinomio:
```csharp
var isValidAssociation = await dbContext.Assignments
    .AnyAsync(a => a.CampaignId == campaignId 
                && a.CreativeId == creativeId 
                && a.PlacementId == placementId);

if (!isValidAssociation)
    throw new InvalidOperationException("La combinación Campaign-Creative-Placement no es válida.");
```

### 2. Control de Estado en Serving (IsEnabled)
Durante la fase de Serving, se descartan los placements y creativos inactivos:
```csharp
var placement = await dbContext.Placements.FindAsync(placementId);
if (placement == null || !placement.IsEnabled) return null;

var creative = await dbContext.Creatives.FindAsync(creativeId);
if (creative == null || !creative.IsEnabled) return null;
```

### 3. Autorización Multi-Tenant Completa y Rate Limiting
- **Aislamiento Multi-Tenant:** Cada controlador valida el Tenant resuelto en `HttpContext.Items["TenantId"]` contra la entidad consultada. No se permite lectura ni modificación cruzada de recursos.
- **Rate Limiting:** Implementado mediante `Microsoft.AspNetCore.RateLimiting` limitando las peticiones a endpoints críticos como `/status` y registro de eventos `/click` o `/impression` para mitigar ataques DoS.

### 4. Seguridad de URLs y Antifraude de Tráfico
- **Sanitización de TargetUrl y ContentUrl:** Expresión regular y validación de esquema URI para asegurar que solo se permitan protocolos seguros (`https://`) y evitar ataques de redirección abierta o XSS por inyección de esquemas `javascript:`.
- **Antifraude de Tráfico:** Filtrado de IPs sospechosas, detección de firmas repetitivas y validación de marcas de tiempo rápidas para evitar la falsificación masiva de impresiones y clics.
