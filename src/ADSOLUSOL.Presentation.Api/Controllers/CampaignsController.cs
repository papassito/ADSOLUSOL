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
    private string TenantId => HttpContext.Items["TenantId"] as string ?? "e2e-tenant";
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
    public async Task<IActionResult> CreateCampaign([FromHeader(Name = "X-Tenant-Id")] string tenantId, [FromBody] CreateCampaignRequest request)
    {
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            return BadRequest(new { Message = "El encabezado X-Tenant-Id es obligatorio." });
        }

        var campaign = await _campaignService.CreateAsync(tenantId, request.Name, request.Budget);

        return CreatedAtAction(nameof(GetCampaignById), new { id = campaign.Id }, campaign);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetCampaignById([FromHeader(Name = "X-Tenant-Id")] string tenantId, string id)
    {
        var campaign = await _campaignService.GetAsync(tenantId, id);
        if (campaign == null) return NotFound();
        return Ok(campaign);
    }

    [HttpGet]
    public async Task<IActionResult> GetAllCampaigns([FromHeader(Name = "X-Tenant-Id")] string tenantId)
    {
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            return BadRequest(new { Message = "El encabezado X-Tenant-Id es obligatorio." });
        }

        var campaigns = await _campaignService.ListAsync(tenantId, CancellationToken.None);
        return Ok(campaigns);
    }

    [HttpPost("{id}/status")]
    public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateStatusRequest request)
    {
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
        var metrics = await _metricsService.GetMetricsForCampaign(id);
        return metrics is null ? NotFound() : Ok(metrics);
    }

    [HttpPost("{id}/click")]
    public async Task<IActionResult> RegisterClick(string id, [FromBody] EventRequest request)
    {
        return await RegisterEventAsync(TenantId, id, request, EventType.Click);
    }

    [HttpPost("{id}/impression")]
    public async Task<IActionResult> RegisterImpression(string id, [FromBody] EventRequest request)
    {
        return await RegisterEventAsync(TenantId, id, request, EventType.Impression);
    }

    private async Task<IActionResult> RegisterEventAsync(string tenantId, string campaignId, EventRequest request, EventType eventType)
    {
        var adEvent = new AdEvent
        {
            EventId = request.EventId,
            CampaignId = campaignId,
            CreativeId = request.CreativeId.ToString(),
            PlacementCode = request.PlacementCode,
            TenantId = tenantId,
            EventType = eventType.ToString().ToUpper(),
            OccurredAt = DateTime.UtcNow,
            ReceivedAt = DateTime.UtcNow
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

public record EventRequest(string EventId, long CreativeId, string PlacementCode);
