using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CampaignsController : ControllerBase
{
    private readonly ICampaignRepository _campaignRepository;

    public CampaignsController(ICampaignRepository campaignRepository)
    {
        _campaignRepository = campaignRepository;
    }

    [HttpPost]
    public async Task<IActionResult> CreateCampaign([FromHeader(Name = "X-Tenant-Id")] string tenantId, [FromBody] CreateCampaignRequest request)
    {
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            return BadRequest(new { Message = "El encabezado X-Tenant-Id es obligatorio." });
        }

        var campaign = new Campaign
        {
            Id = Guid.NewGuid().ToString(),
            TenantId = tenantId,
            Name = request.Name,
            Budget = request.Budget,
            BudgetSpent = 0,
            Status = "ACTIVE",
            CostPerMille = request.CostPerMille,
            CostPerClick = request.CostPerClick,
            StartDateUtc = request.StartDateUtc ?? DateTime.UtcNow,
            EndDateUtc = request.EndDateUtc ?? DateTime.UtcNow.AddDays(30),
            CreatedAt = DateTime.UtcNow
        };

        await _campaignRepository.CreateAsync(campaign);

        return CreatedAtAction(nameof(GetCampaignById), new { id = campaign.Id }, campaign);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetCampaignById(string id)
    {
        var campaign = await _campaignRepository.GetByIdAsync(id);
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

        var campaigns = await _campaignRepository.GetAllAsync(tenantId);
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
