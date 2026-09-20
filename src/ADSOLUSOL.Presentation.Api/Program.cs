﻿﻿﻿using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Authentication;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
using ADSOLUSOL.Presentation.Api.Middleware;
using ADSOLUSOL.Presentation.Api.Components;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
builder.Services.AddScoped<IAdEventRepository, AdEventRepository>();
builder.Services.AddSingleton<ICoreSignatureVerifier, ADSOLUSOL.Infrastructure.Cryptography.CoreSignatureVerifier>();
builder.Services.AddSingleton<INodeRegistry, NodeRegistry>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<BudgetService>();
builder.Services.AddScoped<EventProcessingService>();
builder.Services.AddScoped<MetricsService>();

// Per README, the Marketing Brain integration is not yet real. Register a no-op service.
builder.Services.AddSingleton<IMarketingBrainService, NoOpMarketingBrainService>();

builder.Services.AddControllers();
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseStaticFiles(); // Para CSS, JS, etc. de Blazor
app.UseAntiforgery();

app.UseMiddleware<SignatureVerificationMiddleware>();

app.UseAuthorization();

app.MapControllers();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();

/// <summary>
/// Dummy implementation for the Marketing Brain service, as the real integration is not yet complete.
/// This allows the rest of the application to compile and run without depending on the external service.
/// </summary>
public class NoOpMarketingBrainService : IMarketingBrainService
{
    public Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0) => Task.CompletedTask;

    public Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default) => Task.FromResult(true);

    public Task<bool> PingAsync() => Task.FromResult(true);
}