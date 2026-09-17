using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CampaignsController : ControllerBase
{
    private readonly CampaignService _campaignService;

    public CampaignsController(CampaignService campaignService)
    {
        _campaignService = campaignService;
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

        var campaigns = await _campaignService.ListAsync(tenantId);
        return Ok(campaigns);
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
