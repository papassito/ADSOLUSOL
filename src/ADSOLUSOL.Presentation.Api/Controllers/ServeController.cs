using ADSOLUSOL.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/marketing/adsolusol/serve")]
public class ServeController : ControllerBase
{
    private readonly AdServingService _adServingService;
    private string TenantId => HttpContext.Items["TenantId"] as string ?? "solusol-internal";

    public ServeController(AdServingService adServingService)
    {
        _adServingService = adServingService;
    }

    [HttpGet]
    public async Task<IActionResult> ServeAd([FromQuery] string placementId)
    {
        if (string.IsNullOrWhiteSpace(placementId))
        {
            return BadRequest(new { error = "placementId is required." });
        }

        var decision = await _adServingService.SelectAdForPlacement(TenantId, placementId);

        return decision == null 
            ? NoContent() // Standard HTTP 204 for "NO_AD_AVAILABLE"
            : Ok(decision);
    }
}
