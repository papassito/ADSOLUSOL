using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Integration;
using ADSOLUSOL.Infrastructure.Security;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
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
builder.Services.AddSingleton<ICoreSignatureVerifier, CoreSignatureVerifier>();
builder.Services.AddSingleton<INodeRegistry, NodeRegistry>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<BudgetService>();
builder.Services.AddScoped<EventProcessingService>();
builder.Services.AddScoped<MetricsService>();

// Registrar la implementación real del cliente de Marketing Brain, según HISTORIAL_ACTUALIZACIONES.md
builder.Services.AddScoped<IMarketingBrainService, MarketingBrainClient>();

// FIX: Register dependencies for HealthController and SignatureVerificationMiddleware
builder.Services.AddHttpClient();
builder.Services.AddMemoryCache();

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// FIX: Ensure the database schema is created in development environments.
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    dbContext.Database.EnsureCreated();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseMiddleware<SignatureVerificationMiddleware>();

app.UseAuthorization();

app.MapControllers();

app.Run();

// La implementación ficticia 'NoOpMarketingBrainService' ya no es necesaria y puede ser eliminada.