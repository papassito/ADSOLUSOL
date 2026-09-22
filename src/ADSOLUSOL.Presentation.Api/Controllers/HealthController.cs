﻿﻿using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ADSOLUSOL.Infrastructure.Persistence.AppDbContext _context;
    private readonly IMarketingBrainService _marketingBrainService;

    public HealthController(
        IConfiguration configuration,
        ADSOLUSOL.Infrastructure.Persistence.AppDbContext context,
        IMarketingBrainService marketingBrainService)
    {
        _configuration = configuration;
        _context = context;
        _marketingBrainService = marketingBrainService;
    }

    [HttpGet]
    public async Task<IActionResult> GetHealthStatus(CancellationToken cancellationToken)
    {
        var isDbHealthy = false;
        try
        {
            isDbHealthy = await _context.Database.CanConnectAsync(cancellationToken);
        }
        catch (Exception)
        {
            isDbHealthy = false;
        }

        var isSicHealthy = false;
        try
        {
            isSicHealthy = await _marketingBrainService.IsAvailableAsync(cancellationToken);
        }
        catch (Exception)
        {
            isSicHealthy = false;
        }

        var isHealthy = isDbHealthy && isSicHealthy;
        var statusObject = new
        {
            Status = isHealthy ? "Healthy" : (isDbHealthy ? "Degraded" : "Unhealthy"),
            Timestamp = DateTime.UtcNow,
            Checks = new
            {
                Database = isDbHealthy ? "UP" : "DOWN",
                SicEngine = isSicHealthy ? "UP" : "DOWN"
            }
        };

        return Ok(statusObject);
    }
}
