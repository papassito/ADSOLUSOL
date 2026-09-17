using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Presentation.Api.Security;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
public class MarketingController : ControllerBase
{
    private readonly CoreSignatureVerifier _verifier;
    private readonly IMarketingBrainService _marketingBrainService;

    public MarketingController(CoreSignatureVerifier verifier, IMarketingBrainService marketingBrainService)
    {
        _verifier = verifier;
        _marketingBrainService = marketingBrainService;
    }

    // GET /api/marketing/seo
    [HttpGet("/api/marketing/seo")]
    public IActionResult GetSeoReport()
    {
        // El motor de SEO está desconectado. Las mitigaciones de seguridad contra SSRF están pendientes.
        // Cumpliendo con el principio Zero-Synthetic, retornamos 503 de forma explícita.
        return StatusCode(StatusCodes.Status503ServiceUnavailable, new
        {
            status = "UNAVAILABLE",
            verificationState = "UNVERIFIED",
            reason = "SEO Crawler is offline. Security review for SSRF protection is in progress."
        });
    }

    // POST /api/marketing/adsolusol/campaigns/{id}/toggle
    [HttpPost("/api/marketing/adsolusol/campaigns/{id}/toggle")]
    public async Task<IActionResult> ToggleCampaign(string id)
    {
        var authResult = await VerifySignatureAndAuthorize();
        if (authResult != null) return authResult;

        return Ok(new { status = "SUCCESS", campaignId = id });
    }

    // POST /api/marketing/adsolusol/campaigns/{id}/click
    [HttpPost("/api/marketing/adsolusol/campaigns/{id}/click")]
    public async Task<IActionResult> RecordClick(string id)
    {
        var authResult = await VerifySignatureAndAuthorize();
        if (authResult != null) return authResult;

        await _marketingBrainService.EmitTelemetryAsync("ADS_CLICK", new { campaign_id = id, timestamp = DateTime.UtcNow });

        return Ok(new { status = "VERIFIED_CLICK", campaignId = id });
    }

    // POST /api/marketing/adsolusol/campaigns/{id}/impression
    [HttpPost("/api/marketing/adsolusol/campaigns/{id}/impression")]
    public async Task<IActionResult> RecordImpression(string id)
    {
        var authResult = await VerifySignatureAndAuthorize();
        if (authResult != null) return authResult;

        await _marketingBrainService.EmitTelemetryAsync("ADS_IMPRESSION", new { campaign_id = id, timestamp = DateTime.UtcNow });

        return Ok(new { status = "VERIFIED_IMPRESSION", campaignId = id });
    }

    private async Task<string> ReadBodyAsync()
    {
        Request.EnableBuffering();
        using var reader = new StreamReader(Request.Body, Encoding.UTF8, leaveOpen: true);
        var body = await reader.ReadToEndAsync();
        Request.Body.Position = 0;
        return body;
    }

    private async Task<IActionResult?> VerifySignatureAndAuthorize()
    {
        string nodeId = Request.Headers["X-Solusol-Node-Id"].ToString();
        string timestamp = Request.Headers["X-Solusol-Timestamp"].ToString();
        string nonce = Request.Headers["X-Solusol-Nonce"].ToString();
        string signature = Request.Headers["X-Solusol-Signature"].ToString();
        string jsonBody = await ReadBodyAsync();

        var state = _verifier.VerifySignature(nodeId, timestamp, nonce, jsonBody, signature);

        if (state == VerificationState.NotConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                status = "UNAVAILABLE",
                verificationState = "NOT_CONFIGURED",
                reason = "La clave pública para el NodeID no está configurada."
            });
        }

        if (state != VerificationState.Verified)
        {
            return Unauthorized("La firma criptográfica es inválida o no está configurada.");
        }

        return null; // Indicates success
    }
}