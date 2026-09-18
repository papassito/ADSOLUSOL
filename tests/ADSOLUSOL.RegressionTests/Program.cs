﻿using ADSOLUSOL.Application.Services;
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

Console.WriteLine("==============================================================================");
Console.WriteLine(" ADSOLUSOL - SUITE DE REGRESIÓN DE NEGOCIO (ENTORNO VERIFICADO)");
Console.WriteLine("==============================================================================");

using var host = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration(config =>
    {
        // Use a shared in-memory database for the entire test run.
        config.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["ConnectionStrings:DefaultConnection"] = "DataSource=file:reg_tests?mode=memory&cache=shared"
        });
    })
    .ConfigureServices((context, services) =>
    {
        // Keep a single connection open to the in-memory database to prevent it from being deleted.
        var connection = new SqliteConnection(context.Configuration.GetConnectionString("DefaultConnection"));
        connection.Open();
        services.AddSingleton(connection);

        services.AddDbContext<AppDbContext>(options => options.UseSqlite(connection));

        // Register all real repositories and services
        services.AddScoped<ICampaignRepository, CampaignRepository>();
        services.AddScoped<IPlacementRepository, PlacementRepository>();
        services.AddScoped<ICreativeRepository, CreativeRepository>();
        services.AddScoped<IAssignmentRepository, AssignmentRepository>();
        services.AddScoped<IAdEventRepository, AdEventRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        services.AddScoped<CampaignService>();
        services.AddScoped<AdServingService>();
        services.AddScoped<BudgetService>();
        services.AddScoped<EventProcessingService>();
        services.AddScoped<MetricsService>();

        // Use a test double for the external SIC dependency
        services.AddSingleton<IMarketingBrainService, MockMarketingBrainService>();
    })
    .Build();

using var scope = host.Services.CreateScope();
var services = scope.ServiceProvider;

try
{
    var dbContext = services.GetRequiredService<AppDbContext>();
    
    await LogTest("[01] Schema creation", async () =>
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

    var campaignA = await LogTest("[02] Campaign creation", async () =>
    {
        var c = await campaignService.CreateAsync("tenant-A", "Campaign A", 100, 1.5m, 0.25m, DateTime.UtcNow.AddDays(-1), DateTime.UtcNow.AddDays(30));
        Assert(c != null && c.TenantId == "tenant-A", "Campaign for tenant-A created.");
        return c;
    });
    
    await LogTest("[03] Campaign tenant isolation", async () =>
    {
        await campaignService.CreateAsync("tenant-B", "Campaign B", 200, 2.0m, 0.30m, null, null);
        var campaignsForA = await campaignService.ListAsync("tenant-A");
        Assert(campaignsForA.Count() == 1 && campaignsForA.First().Id == campaignA.Id, "Tenant-A can only see its own campaigns.");
    });

    var placementId = await LogTest("[04] Placement create", async () =>
    {
        var pId = await placementRepo.CreateAsync(new Placement { PlacementCode = "P1", Name = "Homepage Banner", IsEnabled = true });
        Assert(pId > 0, "Placement persisted.");
        return pId;
    });

    var creativeId = await LogTest("[05] Creative create", async () =>
    {
        var cId = await creativeRepo.CreateAsync(new Creative { Name = "Ad 1", ContentUrl = "http://...", IsEnabled = true });
        Assert(cId > 0, "Creative persisted.");
        return cId;
    });
    
    await LogTest("[06] Campaign <-> Placement persistence", async () =>
    {
        await assignmentRepo.AssignPlacementToCampaignAsync(campaignA.Id, placementId);
        var campaignsForPlacement = await placementRepo.GetEligibleCampaignsAsync("tenant-A", "P1");
        Assert(campaignsForPlacement.Any(c => c.Id == campaignA.Id), "Campaign correctly associated with placement.");
    });

    await LogTest("[07] Campaign <-> Creative persistence", async () =>
    {
        await assignmentRepo.AssignCreativeToCampaignAsync(campaignA.Id, creativeId);
        var creativeForCampaign = await creativeRepo.GetEligibleCreativeForCampaignAsync(campaignA.Id);
        Assert(creativeForCampaign?.Id == creativeId, "Campaign correctly associated with creative.");
    });

    await LogTest("[08] PAUSED campaign does not serve", async () =>
    {
        var ad = await adServingService.SelectAdForPlacement("tenant-A", "P1");
        Assert(ad == null, "No ad served for PAUSED campaign.");
    });

    await campaignService.UpdateStatusAsync("tenant-A", campaignA.Id, "ACTIVE");

    await LogTest("[09] ACTIVE campaign serves eligible creative", async () =>
    {
        var ad = await adServingService.SelectAdForPlacement("tenant-A", "P1");
        Assert(ad != null, "Ad served successfully for ACTIVE campaign.");
    });

    var clickEvent = new AdEvent { EventId = "evt_click_1", CampaignId = campaignA.Id, EventType = "Click", TenantId = "tenant-A" };
    await LogTest("[10] Impression accepted", async () =>
    {
        var impressionEvent = new AdEvent { EventId = "evt_imp_1", CampaignId = campaignA.Id, EventType = "Impression", TenantId = "tenant-A" };
        var status = await eventProcessingService.ProcessEvent(impressionEvent);
        Assert(status == EventProcessingStatus.Accepted, "Impression event accepted and processed.");
    });

    await LogTest("[11] Click accepted", async () =>
    {
        var status = await eventProcessingService.ProcessEvent(clickEvent);
        Assert(status == EventProcessingStatus.Accepted, "Click event accepted and processed.");
    });

    await LogTest("[12] Duplicate EventId rejected", async () =>
    {
        var status = await eventProcessingService.ProcessEvent(clickEvent); // Process same event again
        Assert(status == EventProcessingStatus.Duplicate, "Duplicate event correctly identified and rejected.");
    });

    await LogTest("[13-15] Metrics (Imp, Click, Budget) correct", async () =>
    {
        var metrics = await metricsService.GetMetricsForCampaign(campaignA.Id);
        Assert(metrics != null, "Metrics object is not null.");
        Assert(metrics.Impressions == 1, $"[13] Impression count is correct (Expected: 1, Actual: {metrics.Impressions}).");
        Assert(metrics.Clicks == 1, $"[14] Click count is correct (Expected: 1, Actual: {metrics.Clicks}).");
        Assert(metrics.BudgetSpent == (1.5m / 1000) + 0.25m, $"[15] Budget spent is correct (Expected: 0.2515, Actual: {metrics.BudgetSpent}).");
    });
    
    await LogTest("[16] Overspend rejected", async () =>
    {
        var tinyCampaign = await campaignService.CreateAsync("tenant-C", "Tiny Budget", 0.1m, 1.0m, 0.15m, null, null);
        await campaignService.UpdateStatusAsync("tenant-C", tinyCampaign.Id, "ACTIVE");
        var overspendEvent = new AdEvent { EventId = "evt_over_1", CampaignId = tinyCampaign.Id, EventType = "Click", TenantId = "tenant-C" };
        var status = await eventProcessingService.ProcessEvent(overspendEvent);
        Assert(status == EventProcessingStatus.Rejected, "Event rejected as it would exceed budget.");
    });

    await LogTest("[17] Rejected event does not debit budget", async () =>
    {
        var metrics = await metricsService.GetMetricsForCampaign("tenant-C", "Tiny Budget");
        Assert(metrics?.BudgetSpent == 0, "Budget was not spent on rejected event.");
    });

    Console.WriteLine("\n------------------------------------------------------------------------------");
    Console.ForegroundColor = ConsoleColor.Green;
    Console.WriteLine("✅ All regression tests passed successfully.");
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
    if (!condition) throw new Exception($"Assertion Failed: {message}");
    Console.WriteLine($"  [✓] PASS: {message}");
}

public class MockMarketingBrainService : IMarketingBrainService
{
    public Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0)
    {
        Console.ForegroundColor = ConsoleColor.DarkGray;
        Console.WriteLine($"   [TEST DOUBLE] Telemetry Emit: Campaign='{campaignId}', Event='{eventType}', Cost={cost}");
        Console.ResetColor();
        return Task.CompletedTask;
    }
    public Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default) => Task.FromResult(true);
    public Task<bool> PingAsync() => Task.FromResult(true);
}
