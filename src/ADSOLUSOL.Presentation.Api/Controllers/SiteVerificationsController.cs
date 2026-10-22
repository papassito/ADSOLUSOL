using ADSOLUSOL.Presentation.Api.SiteVerification;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/SiteVerifications")]
public sealed class SiteVerificationsController : ControllerBase
{
    private readonly SiteVerificationService _service;
    public SiteVerificationsController(SiteVerificationService service) => _service = service;
    private string? Tenant => HttpContext.Items["TenantId"] as string;

    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] string targetUrl, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(Tenant)) return Forbid();
        try
        {
            var proof = await _service.GetAsync(Tenant, targetUrl, ct);
            return proof is null ? NotFound(new { message = "Aún no se ha generado un código para este dominio." }) : Ok(proof);
        }
        catch (ArgumentException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPost]
    [EnableRateLimiting("site-verification")]
    public async Task<IActionResult> Create([FromBody] SiteVerificationRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(Tenant)) return Forbid();
        try { return Ok(await _service.GetOrCreateAsync(Tenant, request.TargetUrl, ct)); }
        catch (ArgumentException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPost("verify")]
    [EnableRateLimiting("site-verification")]
    public async Task<IActionResult> Verify([FromBody] SiteVerificationRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(Tenant)) return Forbid();
        try
        {
            var proof = await _service.VerifyAsync(Tenant, request.TargetUrl, ct);
            return proof is null ? NotFound(new { message = "Genera el código antes de verificar." }) : Ok(proof);
        }
        catch (ArgumentException ex) { return BadRequest(new { message = ex.Message }); }
    }
}

public sealed record SiteVerificationRequest(string TargetUrl);
