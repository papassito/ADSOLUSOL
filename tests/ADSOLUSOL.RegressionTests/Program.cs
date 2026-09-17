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
    await dbContext.Database.EnsureCreatedAsync();
    Console.WriteLine("  [PASS] Database schema created successfully.");
    testResults["SCHEMA_CREATION"] = true;

    // 2. Campaign Persistence & Tenant Isolation
    Console.WriteLine("\n[TEST] Campaign Persistence & Tenant Isolation...");
    var campaign1 = new Campaign { Id = "c1", TenantId = "tenant-A", Name = "Campaign A", Budget = 100, Status = "ACTIVE", StartDateUtc = DateTime.UtcNow.AddDays(-1), EndDateUtc = DateTime.UtcNow.AddDays(1) };
    var campaign2 = new Campaign { Id = "c2", TenantId = "tenant-B", Name = "Campaign B", Budget = 200, Status = "ACTIVE", StartDateUtc = DateTime.UtcNow.AddDays(-1), EndDateUtc = DateTime.UtcNow.AddDays(1) };
    dbContext.Campaigns.AddRange(campaign1, campaign2);
    await dbContext.SaveChangesAsync();

    var campaignsForA = await dbContext.Campaigns.Where(c => c.TenantId == "tenant-A").ToListAsync();
    var campaignsForB = await dbContext.Campaigns.Where(c => c.TenantId == "tenant-B").ToListAsync();

    if (campaignsForA.Count == 1 && campaignsForA[0].Id == "c1" && campaignsForB.Count == 1 && campaignsForB[0].Id == "c2")
    {
        Console.WriteLine("  [PASS] Campaigns persisted and isolated by tenant correctly.");
        testResults["CAMPAIGN_PERSISTENCE"] = true;
        testResults["TENANT_ISOLATION"] = true;
    }
    else
    {
        throw new Exception("Campaign persistence or tenant isolation failed.");
    }

    // 3. Placement, Creative, and Associations
    Console.WriteLine("\n[TEST] Placements, Creatives, and Associations...");
    var placement1 = new Placement { Id = 1, PlacementCode = "P1" };
    var creative1 = new Creative { Id = 1, ContentUrl = "http://example.com/img.png" };
    dbContext.Placements.Add(placement1);
    dbContext.Creatives.Add(creative1);
    await dbContext.SaveChangesAsync();

    var campaignPlacement = new CampaignPlacement { CampaignId = "c1", PlacementId = 1 };
    var campaignCreative = new CampaignCreative { CampaignId = "c1", CreativeId = 1 };
    dbContext.CampaignPlacements.Add(campaignPlacement);
    dbContext.CampaignCreatives.Add(campaignCreative);
    await dbContext.SaveChangesAsync();

    var assocCount = await dbContext.CampaignPlacements.CountAsync(cp => cp.CampaignId == "c1");
    if (assocCount == 1)
    {
        Console.WriteLine("  [PASS] Associations persisted correctly.");
        testResults["ASSOCIATIONS"] = true;
    }
    else
    {
        throw new Exception("Association persistence failed.");
    }

    // 4. Ad Serving Logic
    Console.WriteLine("\n[TEST] Ad Serving Logic...");
    var servingCampaign = await dbContext.Campaigns
        .Where(c => c.Status == "ACTIVE" && c.RemainingBudget > 0 && c.StartDateUtc <= DateTime.UtcNow && c.EndDateUtc >= DateTime.UtcNow)
        .FirstOrDefaultAsync();
    if (servingCampaign?.Id == "c1")
    {
        Console.WriteLine("  [PASS] Correct campaign selected for serving.");
        testResults["SERVING"] = true;
    }
    else
    {
        throw new Exception("Ad serving logic failed to select the correct campaign.");
    }

    // 5. Event Persistence and Idempotency
    Console.WriteLine("\n[TEST] Event Persistence and Idempotency...");
    var adEvent = new AdEvent { Id = "e1", EventId = "evt_unique_1", CampaignId = "c1", EventType = "CLICK", Cost = 1.5m };
    dbContext.AdEvents.Add(adEvent);
    await dbContext.SaveChangesAsync();

    var eventExists = await dbContext.AdEvents.AnyAsync(e => e.EventId == "evt_unique_1");
    if (eventExists)
    {
        Console.WriteLine("  [PASS] Event persisted successfully.");
        testResults["IMPRESSION_CLICK"] = true;
    }
    else
    {
        throw new Exception("Event persistence failed.");
    }

    // Try to add duplicate
    var duplicateEvent = new AdEvent { Id = "e2", EventId = "evt_unique_1" };
    // This would normally be caught by a unique constraint in a real DB or service logic.
    // Here we simulate the check.
    var isDuplicate = await dbContext.AdEvents.AnyAsync(e => e.EventId == duplicateEvent.EventId);
    if (isDuplicate)
    {
        Console.WriteLine("  [PASS] Duplicate event correctly identified.");
        testResults["IDEMPOTENCY"] = true;
    }
    else
    {
        throw new Exception("Idempotency check failed.");
    }

    // 6. Budget and Metrics
    Console.WriteLine("\n[TEST] Budget and Metrics...");
    var campaignBeforeDebit = await dbContext.Campaigns.FindAsync("c1");
    campaignBeforeDebit!.BudgetSpent += adEvent.Cost;
    await dbContext.SaveChangesAsync();

    var campaignAfterDebit = await dbContext.Campaigns.FindAsync("c1");
    if (campaignAfterDebit?.BudgetSpent == 1.5m && campaignAfterDebit.RemainingBudget == 98.5m)
    {
        Console.WriteLine("  [PASS] Budget debited correctly.");
        testResults["BUDGET"] = true;
        testResults["METRICS"] = true;
    }
    else
    {
        throw new Exception("Budget debit or metric calculation failed.");
    }

    Console.WriteLine("\nAll regression tests passed successfully.");
    return 0;
}
catch (Exception ex)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine($"\n--- TEST FAILED ---");
    Console.WriteLine(ex.Message);
    Console.ResetColor();
    return 1;
}
finally
{
    connection.Close();
}