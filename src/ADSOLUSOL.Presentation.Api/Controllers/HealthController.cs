using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;

    public HealthController(IConfiguration configuration, IHttpClientFactory httpClientFactory)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
    }

    [HttpGet]
    public async Task<IActionResult> GetHealthStatus()
    {
        var isDbHealthy = false;
        var isSicHealthy = false;

        try
        {
            using var connection = new SqliteConnection(_configuration.GetConnectionString("DefaultConnection"));
            await connection.OpenAsync();
            isDbHealthy = true;
        }
        catch { }

        try
        {
            var client = _httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(2);
            var response = await client.GetAsync("http://localhost:8080/health");
            isSicHealthy = response.IsSuccessStatusCode;
        }
        catch { }

        var status = new
        {
            Status = (isDbHealthy && isSicHealthy) ? "Healthy" : "Degraded",
            Timestamp = DateTime.UtcNow,
            Checks = new
            {
                Database = isDbHealthy ? "UP" : "DOWN",
                SicEngine = isSicHealthy ? "UP" : "DOWN"
            }
        };

        return Ok(status);
    }
}
