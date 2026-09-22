﻿﻿﻿﻿﻿using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ADSOLUSOL.Infrastructure.Persistence.AppDbContext _context;

    public HealthController(IConfiguration configuration, ADSOLUSOL.Infrastructure.Persistence.AppDbContext context)
    {
        _configuration = configuration;
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetHealthStatus()
    {
        var isDbHealthy = false;
        try
        {
            isDbHealthy = await _context.Database.CanConnectAsync();
        }
        catch { }

        var statusObject = new
        {
            Status = isDbHealthy ? "Healthy" : "Degraded",
            Timestamp = DateTime.UtcNow,
            Checks = new
            {
                Database = isDbHealthy ? "UP" : "DOWN"
            }
        };

        return Ok(statusObject);
    }
}
