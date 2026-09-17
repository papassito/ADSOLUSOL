using System;
using System.ComponentModel.DataAnnotations;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Application.Enums;
using Microsoft.AspNetCore.Mvc;
using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Presentation.Api.Controllers
{
    [ApiController]
    [Route("api/marketing/adsolusol/campaigns")]
    public class CampaignsController : ControllerBase
    {
        private readonly CampaignService _campaignService; // Good
        private readonly MetricsService _metricsService; // Good
        private readonly EventProcessingService _eventProcessingService; // Good

        public CampaignsController(
            CampaignService campaignService,
            MetricsService metricsService,
            EventProcessingService eventProcessingService
            )
        {
            _campaignService = campaignService;
            _metricsService = metricsService;
            _eventProcessingService = eventProcessingService;
        }

        private string TenantId => HttpContext.Items["TenantId"] as string ?? "solusol-internal";

        // Endpoints from the newer CampaignController, now integrated here.
        [HttpGet]
        public async Task<IActionResult> Get(CancellationToken token) => Ok(await _campaignService.ListAsync(TenantId, token));

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id, CancellationToken token)
        {
            var campaign = await _campaignService.GetAsync(TenantId, id, token);
            return campaign is null ? NotFound() : Ok(campaign);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateCampaignRequest request, CancellationToken token)
        {
            var campaign = await _campaignService.CreateAsync(TenantId, request.Name, request.Budget, token);
            return Created($"/api/marketing/adsolusol/campaigns/{campaign.Id}", campaign);
        }

        [HttpGet("{id}/metrics")]
        public async Task<IActionResult> GetMetrics(string id)
        {
            var metrics = await _metricsService.GetMetricsForCampaign(TenantId, id);
            return metrics is null ? NotFound() : Ok(metrics);
        }

        [HttpPost("{id}/toggle")]
        public async Task<IActionResult> ToggleStatus(string id, [FromBody] UpdateStatusRequest request)
        {
            // Assuming CampaignService has a method to update status.
            // This replaces the old _processingEngine logic.
            var updatedCampaign = await _campaignService.UpdateStatusAsync(TenantId, id, request.Status);
            if (updatedCampaign is null)
            {
                return NotFound(new { error = "Campaign not found." });
            }

            return Ok(new { status = "SUCCESS", campaignId = id, newStatus = updatedCampaign.Status });
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
                CreativeId = request.CreativeId,
                PlacementCode = request.PlacementCode,
                TenantId = tenantId,
                EventType = eventType.ToString().ToUpper(),
                OccurredAt = DateTime.UtcNow, // Should ideally come from client, but server time is a safe default
                ReceivedAt = DateTime.UtcNow
            };

            try
            {
                var result = await _eventProcessingService.ProcessEvent(adEvent);

                return result switch
                {
                    EventProcessingStatus.Duplicate => Ok(new { status = "DUPLICATE", message = "Event already processed. Idempotency enforced." }),
                    EventProcessingStatus.Rejected => BadRequest(new { error = "Campaign is inactive, has no budget, or event is invalid." }),
                    EventProcessingStatus.Accepted => Accepted(new { status = "ACCEPTED" }),
                    _ => StatusCode(500, new { error = "An unknown error occurred during event processing." })
                };
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}

public sealed class CreateCampaignRequest
{
    [Required, StringLength(200, MinimumLength = 1)]
    public string Name { get; set; } = "";
    [Range(typeof(decimal), "0.00000001", "79228162514264337593543950335")]
    public decimal Budget { get; set; }
}

public record UpdateStatusRequest([Required] string Status);

public record EventRequest([Required] string EventId, [Required] long CreativeId, [Required] string PlacementCode);