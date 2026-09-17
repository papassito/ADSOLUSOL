using ADSOLUSOL.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ServeController : ControllerBase
{
    private readonly AdServingService _adServingService;
    private string TenantId => HttpContext.Items["TenantId"] as string 
        ?? throw new InvalidOperationException("TenantId no fue encontrado en el contexto de la solicitud.");

    public ServeController(AdServingService adServingService)
    {
        _adServingService = adServingService;
    }

    [HttpGet]
    public async Task<IActionResult> ServeAd([FromQuery] string placementCode)
    {
        var result = await _adServingService.SelectAdForPlacement(TenantId, placementCode);
        if (result == null)
        {
            return NotFound(new { message = "No eligible ads available for this placement." });
        }

        return Ok(result);
    }
}
