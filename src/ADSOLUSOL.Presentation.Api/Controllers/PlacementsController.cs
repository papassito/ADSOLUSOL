using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PlacementsController : ControllerBase
{
    private readonly IPlacementRepository _placementRepository;

    public PlacementsController(IPlacementRepository placementRepository)
    {
        _placementRepository = placementRepository;
    }

    [HttpPost]
    public async Task<IActionResult> CreatePlacement([FromBody] Placement placement)
    {
        placement.CreatedAtUtc = DateTime.UtcNow;
        placement.UpdatedAtUtc = DateTime.UtcNow;
        var id = await _placementRepository.CreateAsync(placement);
        return CreatedAtAction("CreatePlacement", new { placementCode = placement.PlacementCode }, new { id });
    }
}
