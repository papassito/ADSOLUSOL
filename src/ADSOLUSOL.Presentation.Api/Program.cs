using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Presentation.Api.Health;
using ADSOLUSOL.Presentation.Api.Security;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
if (string.IsNullOrEmpty(builder.Configuration["urls"])) builder.WebHost.UseUrls("http://127.0.0.1:5080");
builder.Services.AddControllers();
var databasePath = Path.GetFullPath(builder.Configuration["Storage:Path"] ?? "App_Data/campaigns.db", builder.Environment.ContentRootPath);
builder.Services.AddScoped(_ => new AppDbContext(databasePath));
builder.Services.AddScoped<IAppDbContext>(services => services.GetRequiredService<AppDbContext>());
builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<CoreSignatureVerifier>();
builder.Services.AddHttpClient<IMarketingBrainService, MarketingBrainClient>((serviceProvider, client) =>
{
    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
    client.BaseAddress = new Uri(configuration["SolusolAuthV1:SicBaseUrl"] ?? "http://127.0.0.1:8080");
});
builder.Services.AddMemoryCache();
builder.Services.AddHealthChecks()
    .AddCheck<PersistenceHealthCheck>("persistence", tags: ["core"])
    .AddCheck<MarketingBrainHealthCheck>("marketingBrain", tags: ["integration"]);

var app = builder.Build();
app.Use(async (context, next) =>
{
    context.Response.Headers.CacheControl = "no-store";
    try
    {
        if (!context.Request.Path.StartsWithSegments("/api/health"))
        {
            var key = app.Configuration["Api:Key"];
            if (string.IsNullOrWhiteSpace(key))
            {
                context.Response.StatusCode = 503;
                await context.Response.WriteAsJsonAsync(new { status = "UNAVAILABLE", code = "API_KEY_NOT_CONFIGURED" });
                return;
            }
            var provided = context.Request.Headers["X-Api-Key"].ToString();
            if (!CryptographicOperations.FixedTimeEquals(SHA256.HashData(Encoding.UTF8.GetBytes(key)), SHA256.HashData(Encoding.UTF8.GetBytes(provided))))
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsJsonAsync(new { code = "UNAUTHORIZED" });
                return;
            }
        }
        await next(context);
    }
    catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested) { context.Abort(); }
    catch (Exception e) when (e is SqliteException or IOException or UnauthorizedAccessException or HttpRequestException or InvalidOperationException or JsonException or OperationCanceledException)
    {
        app.Logger.LogWarning("Dependency operation failed ({ExceptionType}).", e.GetType().Name);
        context.Response.StatusCode = 503;
        await context.Response.WriteAsJsonAsync(new { status = "UNAVAILABLE", code = "DEPENDENCY_UNAVAILABLE" });
    }
    catch (ArgumentException)
    {
        context.Response.StatusCode = 400;
        await context.Response.WriteAsJsonAsync(new { code = "INVALID_CAMPAIGN" });
    }
});
app.MapControllers();
HealthCheckOptions HealthOptions(string? tag = null) => new()
{
    Predicate = registration => tag is null || registration.Tags.Contains(tag),
    ResultStatusCodes = { [HealthStatus.Healthy] = 200, [HealthStatus.Degraded] = 503, [HealthStatus.Unhealthy] = 503 },
    ResponseWriter = (context, report) => context.Response.WriteAsJsonAsync(new
    {
        status = report.Status == HealthStatus.Healthy ? "AVAILABLE" : "UNAVAILABLE",
        dependencies = report.Entries.ToDictionary(entry => entry.Key, entry => entry.Value.Status == HealthStatus.Healthy ? "AVAILABLE" : "UNAVAILABLE")
    }, cancellationToken: context.RequestAborted)
};
app.MapHealthChecks("/api/health", HealthOptions());
app.MapHealthChecks("/api/health/storage", HealthOptions("core"));
app.Run();
