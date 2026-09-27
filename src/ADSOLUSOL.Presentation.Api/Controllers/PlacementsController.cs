using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PlacementsController : ControllerBase
{
    private string? TenantId => HttpContext.Items["TenantId"] as string;
    private readonly IPlacementRepository _placementRepository;

    public PlacementsController(IPlacementRepository placementRepository)
    {
        _placementRepository = placementRepository;
    }

    [HttpGet("{code}")]
    public async Task<IActionResult> GetByCode(string code)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var placement = await _placementRepository.GetByCodeAsync(code);
        if (placement is null)
        {
            return NotFound();
        }
        return Ok(placement);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var placements = await _placementRepository.GetAllAsync();
        return Ok(placements);
    }

    [HttpPost]
    public async Task<IActionResult> CreatePlacement([FromBody] Placement placement)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        placement.CreatedAt = DateTime.UtcNow;
        placement.UpdatedAt = DateTime.UtcNow;
        var id = await _placementRepository.CreateAsync(placement);
        return CreatedAtAction(nameof(GetByCode), new { code = placement.PlacementCode }, new { id, placement.PlacementCode });
    }
}
