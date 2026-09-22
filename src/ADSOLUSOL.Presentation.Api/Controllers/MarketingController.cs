﻿using ADSOLUSOL.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/marketing/adsolusol")]
public class MarketingController : ControllerBase
{
    private readonly IMarketingBrainService _marketingBrainService;

    public MarketingController(IMarketingBrainService marketingBrainService)
    {
        _marketingBrainService = marketingBrainService;
    }

    [HttpGet("status")]
    public async Task<IActionResult> GetStatus(CancellationToken cancellationToken)
    {
        var isAvailable = await _marketingBrainService.IsAvailableAsync(cancellationToken);
        return Ok(new
        {
            service = "MarketingBrain",
            status = isAvailable ? "CONNECTED" : "UNAVAILABLE",
            timestampUtc = DateTime.UtcNow
        });
    }

    [HttpGet("ping")]
    public async Task<IActionResult> Ping()
    {
        var result = await _marketingBrainService.PingAsync();
        return Ok(new { ping = result, timestampUtc = DateTime.UtcNow });
    }
}