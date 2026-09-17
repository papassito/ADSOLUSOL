using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/placements")]
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
        placement.CreatedAt = DateTime.UtcNow;
        placement.UpdatedAt = DateTime.UtcNow;
        var id = await _placementRepository.CreateAsync(placement);
        return CreatedAtAction(nameof(GetPlacement), new { placementCode = placement.PlacementCode }, new { id });
    }

    [HttpGet("{placementCode}")]
    public async Task<IActionResult> GetPlacement(string placementCode)
    {
        var placement = await _placementRepository.GetByCodeAsync(placementCode);
        return placement == null ? NotFound() : Ok(placement);
    }

    [HttpGet]
    public async Task<IActionResult> GetAllPlacements()
    {
        var placements = await _placementRepository.GetAllAsync();
        return Ok(placements);
    }
}