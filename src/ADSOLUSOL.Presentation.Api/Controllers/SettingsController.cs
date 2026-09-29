using ADSOLUSOL.Application.DTOs;
using ADSOLUSOL.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SettingsController : ControllerBase
{
    private readonly ITenantSettingsService _settingsService;

    public SettingsController(ITenantSettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    private string? ResolveTenantId()
    {
        if (HttpContext.Items.TryGetValue("TenantId", out var t) && t is string tid && !string.IsNullOrWhiteSpace(tid))
        {
            return tid;
        }
        return null;
    }

    [HttpGet]
    public async Task<IActionResult> GetSettings()
    {
        var tenantId = ResolveTenantId();
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            return Unauthorized(new { error = "No se pudo resolver un TenantId autorizado para esta petición." });
        }

        var settings = await _settingsService.GetSettingsAsync(tenantId);
        return Ok(settings);
    }

    [HttpPut]
    public async Task<IActionResult> UpdateSettings([FromBody] UpdateTenantSettingsDto dto)
    {
        var tenantId = ResolveTenantId();
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            return Unauthorized(new { error = "No se pudo resolver un TenantId autorizado para esta petición." });
        }

        var updated = await _settingsService.UpdateSettingsAsync(tenantId, dto);
        return Ok(updated);
    }
}