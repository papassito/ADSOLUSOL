using System.ComponentModel.DataAnnotations;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

public sealed class CreateCampaignRequest
{
    [Required, StringLength(200, MinimumLength = 1)]
    public string Name { get; set; } = "";
    [Range(typeof(decimal), "0.00000001", "79228162514264337593543950335")]
    public decimal Budget { get; set; }
}

[ApiController]
[Route("api/[controller]")]
[Route("api/marketing/adsolusol/campaigns")]
public sealed class CampaignController(CampaignService campaigns, IMarketingBrainService brain, IConfiguration config) : ControllerBase
{
    private string Tenant => config["Api:TenantId"] ?? "local";

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken token) => Ok(await campaigns.ListAsync(Tenant, token));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken token)
    {
        var campaign = await campaigns.GetAsync(Tenant, id, token);
        return campaign is null ? NotFound() : Ok(campaign);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateCampaignRequest request, CancellationToken token)
    {
        var campaign = await campaigns.CreateAsync(Tenant, request.Name, request.Budget, token);
        return Created($"/api/marketing/adsolusol/campaigns/{campaign.Id}", campaign);
    }

    // This endpoint is currently disabled as the content generation contract is not defined in IMarketingBrainService.
    // It returns 503 to align with the smoke tests and Zero-Synthetic principles.
    [HttpPost("{id:guid}/content")]
    public async Task<IActionResult> GenerateContent(Guid id, CancellationToken token)
    {
        var campaign = await campaigns.GetAsync(Tenant, id, token);
        if (campaign is null)
        {
            return NotFound();
        }

        var adContent = await brain.GenerateAdContentAsync(campaign, token);

        if (adContent is null)
        {
            return StatusCode(503, new { status = "UNAVAILABLE", reason = "Could not generate ad content from the intelligence service." });
        }

        return Ok(adContent);
    }
}
