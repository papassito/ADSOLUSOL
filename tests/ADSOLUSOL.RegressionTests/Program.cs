using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Enums;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

Console.WriteLine("--- ADSOLUSOL Regression Test Suite ---");
Console.ForegroundColor = ConsoleColor.Cyan;
Console.WriteLine("Building service host and in-memory database...");
Console.ResetColor();

using var host = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration(config =>
    {
        config.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["ConnectionStrings:DefaultConnection"] = "DataSource=file:memdb?mode=memory&cache=shared"
        });
    })
    .ConfigureServices((context, services) =>
    {
        // Keep a single connection open to the in-memory database
        var connection = new SqliteConnection(context.Configuration.GetConnectionString("DefaultConnection"));
        connection.Open();
        services.AddSingleton(connection);

        services.AddDbContext<AppDbContext>(options => options.UseSqlite(connection));

        // Register all repositories
        services.AddScoped<ICampaignRepository, CampaignRepository>();
        services.AddScoped<IPlacementRepository, PlacementRepository>();
        services.AddScoped<ICreativeRepository, CreativeRepository>();
        services.AddScoped<IAssignmentRepository, AssignmentRepository>();
        services.AddScoped<IAdEventRepository, AdEventRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Register all services
        services.AddScoped<CampaignService>();
        services.AddScoped<AdServingService>();
        services.AddScoped<BudgetService>();
        services.AddScoped<EventProcessingService>();
        services.AddScoped<MetricsService>();

        // Mock external services
        services.AddSingleton<IMarketingBrainService, MockMarketingBrainService>();
    })
    .Build();

using var scope = host.Services.CreateScope();
var services = scope.ServiceProvider;

try
{
    var dbContext = services.GetRequiredService<AppDbContext>();
    
    LogTest("Schema Creation", async () =>
    {
        await dbContext.Database.EnsureCreatedAsync();
        Assert(true, "Database schema created successfully.");
    });

    var campaignService = services.GetRequiredService<CampaignService>();
    var assignmentRepo = services.GetRequiredService<IAssignmentRepository>();
    var placementRepo = services.GetRequiredService<IPlacementRepository>();
    var creativeRepo = services.GetRequiredService<ICreativeRepository>();
    var adServingService = services.GetRequiredService<AdServingService>();
    var eventProcessingService = services.GetRequiredService<EventProcessingService>();
    var metricsService = services.GetRequiredService<MetricsService>();

    var campaignA = await LogTest("Campaign Creation", async () =>
    {
        var c = await campaignService.CreateAsync("tenant-A", "Campaign A", 100, 1.5m, 0.25m, DateTime.UtcNow.AddDays(-1), DateTime.UtcNow.AddDays(30));
        Assert(c != null && c.TenantId == "tenant-A", "Campaign for tenant-A created.");
        return c;
    });
    
    await LogTest("Tenant Isolation", async () =>
    {
        await campaignService.CreateAsync("tenant-B", "Campaign B", 200, 2.0m, 0.30m, null, null);
        var campaignsForA = await campaignService.ListAsync("tenant-A");
        Assert(campaignsForA.Count() == 1 && campaignsForA.First().Id == campaignA.Id, "Tenant-A can only see its own campaigns.");
    });

    var placementId = await LogTest("Placement & Creative Persistence", async () =>
    {
        var pId = await placementRepo.CreateAsync(new Placement { PlacementCode = "P1", Name = "Homepage Banner", IsEnabled = true });
        var cId = await creativeRepo.CreateAsync(new Creative { Name = "Ad 1", ContentUrl = "http://...", IsEnabled = true });
        Assert(pId > 0 && cId > 0, "Placement and Creative persisted.");
        return pId;
    });
    
    await LogTest("Association Persistence", async () =>
    {
        await assignmentRepo.AssignPlacementToCampaignAsync(campaignA.Id, placementId);
        await assignmentRepo.AssignCreativeToCampaignAsync(campaignA.Id, 1); // Assuming creative ID is 1
        var campaignsForPlacement = await placementRepo.GetEligibleCampaignsAsync("tenant-A", "P1");
        Assert(campaignsForPlacement.Any(c => c.Id == campaignA.Id), "Campaign correctly associated with placement.");
    });

    await LogTest("Ad Serving Logic (Inactive Campaign)", async () =>
    {
        var ad = await adServingService.SelectAdForPlacement("tenant-A", "P1");
        Assert(ad == null, "No ad served for PAUSED campaign.");
    });

    await campaignService.UpdateStatusAsync("tenant-A", campaignA.Id, "ACTIVE");

    await LogTest("Ad Serving Logic (Active Campaign)", async () =>
    {
        var ad = await adServingService.SelectAdForPlacement("tenant-A", "P1");
        Assert(ad != null, "Ad served successfully for ACTIVE campaign.");
    });

    var clickEvent = new AdEvent { EventId = "evt_click_1", CampaignId = campaignA.Id, EventType = "Click", TenantId = "tenant-A" };
    await LogTest("Event Processing (Click)", async () =>
    {
        var status = await eventProcessingService.ProcessEvent(clickEvent);
        Assert(status == EventProcessingStatus.Accepted, "Click event accepted and processed.");
    });

    await LogTest("Idempotency Check", async () =>
    {
        var status = await eventProcessingService.ProcessEvent(clickEvent); // Process same event again
        Assert(status == EventProcessingStatus.Duplicate, "Duplicate event correctly identified and rejected.");
    });

    await LogTest("Budget & Metrics Verification", async () =>
    {
        var metrics = await metricsService.GetMetricsForCampaign(campaignA.Id);
        Assert(metrics != null, "Metrics object is not null.");
        Assert(metrics.Clicks == 1, $"Click count is correct (Expected: 1, Actual: {metrics.Clicks}).");
        Assert(metrics.Impressions == 0, $"Impression count is correct (Expected: 0, Actual: {metrics.Impressions}).");
        Assert(metrics.BudgetSpent == 0.25m, $"Budget spent is correct (Expected: 0.25, Actual: {metrics.BudgetSpent}).");
    });
    
    await LogTest("Budget Overspend Protection", async () =>
    {
        var tinyCampaign = await campaignService.CreateAsync("tenant-C", "Tiny Budget", 0.1m, 1.0m, 0.15m, null, null);
        await campaignService.UpdateStatusAsync("tenant-C", tinyCampaign.Id, "ACTIVE");
        var overspendEvent = new AdEvent { EventId = "evt_over_1", CampaignId = tinyCampaign.Id, EventType = "Click", TenantId = "tenant-C" };
        var status = await eventProcessingService.ProcessEvent(overspendEvent);
        Assert(status == EventProcessingStatus.Rejected, "Event rejected as it would exceed budget.");
        var metrics = await metricsService.GetMetricsForCampaign(tinyCampaign.Id);
        Assert(metrics?.BudgetSpent == 0, "Budget was not spent on rejected event.");
    });

    Console.ForegroundColor = ConsoleColor.Green;
    Console.WriteLine("\n✅ All regression tests passed successfully.");
    Console.ResetColor();
    return 0;
}
catch (Exception ex)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine($"\n--- TEST FAILED ---");
    Console.WriteLine(ex.ToString());
    Console.ResetColor();
    return 1;
}
finally
{
    // Clean up the in-memory database connection
    services.GetRequiredService<SqliteConnection>().Close();
}

async Task<T> LogTest<T>(string testName, Func<Task<T>> testAction)
{
    Console.WriteLine($"\n[TEST] {testName}...");
    return await testAction();
}

async Task LogTest(string testName, Func<Task> testAction)
{
    Console.WriteLine($"\n[TEST] {testName}...");
    await testAction();
}

void Assert(bool condition, string message)
{
    if (condition)
    {
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"  [PASS] {message}");
        Console.ResetColor();
    }
    else
    {
        throw new Exception($"Assertion Failed: {message}");
    }
}

// Mock implementation for external service
public class MockMarketingBrainService : IMarketingBrainService
{
    public Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0)
    {
        Console.ForegroundColor = ConsoleColor.DarkGray;
        Console.WriteLine($"   [TELEMETRY] Emit: Campaign='{campaignId}', Event='{eventType}', Cost={cost}");
        Console.ResetColor();
        return Task.CompletedTask;
    }
    public Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default) => Task.FromResult(true);
    public Task<bool> PingAsync() => Task.FromResult(true);
}