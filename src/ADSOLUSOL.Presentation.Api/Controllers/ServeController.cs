using ADSOLUSOL.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/serve")]
public class ServeController : ControllerBase
{
    private readonly AdServingService _adServingService;

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

        var decision = await _adServingService.SelectAdForPlacement(placementId);

        return decision == null 
            ? NoContent() // Standard HTTP 204 for "NO_AD_AVAILABLE"
            : Ok(decision);
    }
}