using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CreativesController : ControllerBase
{
    private readonly ICreativeRepository _creativeRepository;

    public CreativesController(ICreativeRepository creativeRepository)
    {
        _creativeRepository = creativeRepository;
    }

    [HttpPost]
    public async Task<IActionResult> CreateCreative([FromBody] Creative creative)
    {
        creative.CreatedAt = DateTime.UtcNow;
        creative.UpdatedAt = DateTime.UtcNow;
        var id = await _creativeRepository.CreateAsync(creative);
        var createdCreative = await _creativeRepository.GetByIdAsync(id);
        return CreatedAtAction(nameof(CreateCreative), new { id }, createdCreative);
    }
}
