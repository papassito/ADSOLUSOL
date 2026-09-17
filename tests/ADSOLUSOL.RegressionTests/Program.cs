using System.Text.Json;
using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Presentation.Api.Health;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var checks = 0;
void Check(bool condition, string message)
{
    checks++;
    if (!condition) throw new Exception(message);
}
async Task ExpectFailure<T>(Func<Task> action) where T : Exception
{
    checks++;
    try { await action(); }
    catch (T) { return; }
    throw new Exception($"Expected {typeof(T).Name}, but operation succeeded.");
}

var campaign = new Campaign();
Check(campaign.Status == "SCHEDULED", "Default status violates contract.");
foreach (var status in new[] { "SCHEDULED", "ACTIVE", "PAUSED", "COMPLETED" })
{
    campaign.Status = status;
    Check(JsonSerializer.Deserialize<Campaign>(JsonSerializer.Serialize(campaign))!.Status == status, "Status must survive JSON round trip.");
}
foreach (var invalid in new string?[] { "Draft", "active", "", null })
{
    await ExpectFailure<ArgumentException>(() => { campaign.Status = invalid!; return Task.CompletedTask; });
    Check(campaign.Status == "COMPLETED", "Rejected assignment changed campaign status.");
}
var folder = Path.Combine(Path.GetTempPath(), "adsolusol-regression-" + Guid.NewGuid().ToString("N"));
Directory.CreateDirectory(folder);
try
{
    var apiProjectDir = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "src", "ADSOLUSOL.Presentation.Api"));
    var configuration = new ConfigurationBuilder()
        .SetBasePath(apiProjectDir)
        .AddJsonFile("appsettings.json", optional: false)
        .Build();

    var services = new ServiceCollection();
    services.AddSingleton<IConfiguration>(configuration);
    services.AddLogging();
    services.AddHttpClient<IMarketingBrainService, MarketingBrainClient>((serviceProvider, client) =>
    {
        var config = serviceProvider.GetRequiredService<IConfiguration>();
        client.BaseAddress = new Uri(config["SolusolAuthV1:SicBaseUrl"] ?? "http://127.0.0.1:8080");
    });
    await using var serviceProvider = services.BuildServiceProvider();

    var path = Path.Combine(folder, "campaigns.db");
    var storage = new AppDbContext(path);
    Check(await storage.IsAvailableAsync(), "SQLite health check failed.");
    Check((await storage.GetCampaignsAsync("tenant-a")).Count == 0, "Health probe inserted synthetic data.");
    Check(await storage.SaveChangesAsync() == 0, "No-op save must return zero.");
    var service = new CampaignService(storage);
    var created = await service.CreateAsync("tenant-a", "Real campaign", 123.4567890123456789012345678m);
    Check(created.Id != Guid.Empty && created.Status == "SCHEDULED", "Invalid new campaign.");
    var reopened = new AppDbContext(path);
    var recovered = await reopened.GetCampaignAsync("tenant-a", created.Id);
    Check(recovered?.Budget == created.Budget && recovered.Name == created.Name, "Disk persistence or monetary precision failed.");
    Check(await reopened.GetCampaignAsync("tenant-b", created.Id) is null, "Cross-tenant read leaked a campaign.");
    Check((await reopened.GetCampaignsAsync("tenant-b")).Count == 0, "Cross-tenant list leaked campaigns.");
    await ExpectFailure<ArgumentException>(async () => { await service.CreateAsync("tenant-a", " ", 1); });
    await ExpectFailure<ArgumentException>(async () => { await service.CreateAsync("tenant-a", "invalid", 0); });

    // A duplicate second insert must roll back the first insert in the same batch.
    var batch = new AppDbContext(path);
    var second = new Campaign { Id = Guid.NewGuid(), TenantId = "tenant-a", Name = "rollback", Budget = 10 };
    batch.AddCampaign(second);
    batch.AddCampaign(created);
    await ExpectFailure<SqliteException>(async () => { await batch.SaveChangesAsync(); });
    Check(await reopened.GetCampaignAsync("tenant-a", second.Id) is null, "Failed batch partially committed.");

    using var cancelled = new CancellationTokenSource();
    cancelled.Cancel();
    await ExpectFailure<OperationCanceledException>(async () => { await storage.SaveChangesAsync(cancelled.Token); });
    await ExpectFailure<OperationCanceledException>(async () => { await storage.GetCampaignsAsync("tenant-a", cancelled.Token); });

    // Multiple independent contexts must not overwrite one another's inserts.
    await Task.WhenAll(Enumerable.Range(0, 8).Select(i => Task.Run(async () =>
        await new CampaignService(new AppDbContext(path)).CreateAsync("tenant-a", $"parallel-{i}", 10))));
    Check((await reopened.GetCampaignsAsync("tenant-a")).Count == 9, "Concurrent writes lost data.");
    var blocked = Path.Combine(folder, "not-a-directory");
    File.WriteAllText(blocked, "blocking file");
    var broken = new AppDbContext(Path.Combine(blocked, "db.sqlite"));
    Check(!await broken.IsAvailableAsync(), "Inaccessible storage reported healthy.");
    Check((await new PersistenceHealthCheck(broken).CheckHealthAsync(new HealthCheckContext())).Status == HealthStatus.Unhealthy, "Storage health ignores failure.");
    Check((await new PersistenceHealthCheck(storage).CheckHealthAsync(new HealthCheckContext())).Status == HealthStatus.Healthy, "Working storage reported unhealthy.");

    var brain = serviceProvider.GetRequiredService<IMarketingBrainService>();
    Check((await new MarketingBrainHealthCheck(brain).CheckHealthAsync(new HealthCheckContext())).Status == HealthStatus.Unhealthy, "SIC integration should be unhealthy if the service is not running.");
    Console.WriteLine($"PASS: {checks} regression checks.");
}
finally
{
    SqliteConnection.ClearAllPools();
    if (Path.GetDirectoryName(Path.GetFullPath(folder)) != Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar)
        || !Path.GetFileName(folder).StartsWith("adsolusol-regression-", StringComparison.Ordinal))
        throw new InvalidOperationException("Unsafe test cleanup path.");
    Directory.Delete(folder, recursive: true);
}
