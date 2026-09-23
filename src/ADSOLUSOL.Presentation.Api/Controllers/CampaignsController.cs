using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CampaignsController : ControllerBase
{
    private string? TenantId => HttpContext.Items["TenantId"] as string;
    private readonly CampaignService _campaignService;
    private readonly MetricsService _metricsService;
    private readonly EventProcessingService _eventProcessingService;

    public CampaignsController(CampaignService campaignService, MetricsService metricsService, EventProcessingService eventProcessingService)
    {
        _campaignService = campaignService;
        _metricsService = metricsService;
        _eventProcessingService = eventProcessingService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateCampaign([FromBody] CreateCampaignRequest request)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new { message = "El nombre de la campaña es requerido." });
        }

        if (request.Budget <= 0)
        {
            return BadRequest(new { message = "El presupuesto debe ser mayor a cero." });
        }

        if (request.CostPerMille < 0 || request.CostPerClick < 0)
        {
            return BadRequest(new { message = "Los costos CPM y CPC no pueden ser negativos." });
        }

        if (request.StartDateUtc.HasValue && request.EndDateUtc.HasValue && request.EndDateUtc < request.StartDateUtc)
        {
            return BadRequest(new { message = "La fecha final no puede ser anterior a la fecha inicial." });
        }

        var campaign = await _campaignService.CreateAsync(TenantId, request.Name, request.Budget, request.CostPerMille, request.CostPerClick, request.StartDateUtc, request.EndDateUtc);

        return CreatedAtAction(nameof(GetCampaignById), new { id = campaign.Id }, campaign);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetCampaignById(string id)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var campaign = await _campaignService.GetAsync(TenantId, id);
        if (campaign == null) return NotFound();
        return Ok(campaign);
    }

    [HttpGet]
    public async Task<IActionResult> GetAllCampaigns()
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var campaigns = await _campaignService.ListAsync(TenantId, CancellationToken.None);
        return Ok(campaigns);
    }

    [HttpPost("{id}/status")]
    public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateStatusRequest request)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var allowedStatuses = new[] { "ACTIVE", "PAUSED", "SCHEDULED", "COMPLETED" };
        var normalizedStatus = request.Status?.Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(normalizedStatus) || !allowedStatuses.Contains(normalizedStatus))
        {
            return BadRequest(new { message = $"Estado inválido: '{request.Status}'. Estados permitidos: ACTIVE, PAUSED, SCHEDULED, COMPLETED." });
        }

        var updatedCampaign = await _campaignService.UpdateStatusAsync(TenantId, id, request.Status);
        if (updatedCampaign is null)
        {
            return NotFound();
        }
        return Ok(updatedCampaign);
    }

    [HttpGet("{id}/metrics")]
    public async Task<IActionResult> GetMetrics(string id)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        // FIX: Authorize access to the campaign before retrieving metrics.
        var campaign = await _campaignService.GetAsync(TenantId, id);
        if (campaign is null)
        {
            return NotFound(); // Do not reveal the existence of a campaign belonging to another tenant.
        }
        var metrics = await _metricsService.GetMetricsForCampaign(id);
        return metrics is null ? NotFound() : Ok(metrics);
    }

    [HttpPost("{id}/click")]
    public async Task<IActionResult> RegisterClick(string id, [FromBody] EventRequest request)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }
        return await RegisterEventAsync(TenantId, id, request, EventType.Click);
    }

    [HttpPost("{id}/impression")]
    public async Task<IActionResult> RegisterImpression(string id, [FromBody] EventRequest request)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }
        return await RegisterEventAsync(TenantId, id, request, EventType.Impression);
    }

    private async Task<IActionResult> RegisterEventAsync(string tenantId, string campaignId, EventRequest request, EventType eventType)
    {
        var adEvent = new AdEvent
        {
            EventId = request.EventId,
            CampaignId = campaignId,
            CreativeId = request.CreativeId,
            PlacementCode = request.PlacementCode,
            TenantId = tenantId,
            EventType = eventType.ToString().ToUpper(),
            TimestampUtc = DateTime.UtcNow
        };

        var status = await _eventProcessingService.ProcessEvent(adEvent);

        return status switch
        {
            EventProcessingStatus.Accepted => Ok(new { status = "ACCEPTED", eventId = adEvent.EventId }),
            EventProcessingStatus.Duplicate => Conflict(new { status = "DUPLICATE", eventId = adEvent.EventId }),
            _ => BadRequest(new { status = "REJECTED" })
        };
    }
}

public class CreateCampaignRequest
{
    public string Name { get; set; } = string.Empty;
    public decimal Budget { get; set; }
    public decimal CostPerMille { get; set; }
    public decimal CostPerClick { get; set; }
    public DateTime? StartDateUtc { get; set; }
    public DateTime? EndDateUtc { get; set; }
}

public record UpdateStatusRequest(string Status);

public record EventRequest(string EventId, string CreativeId, string PlacementCode);
