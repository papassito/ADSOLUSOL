using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Infrastructure.Repositories;
using ADSOLUSOL.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();
builder.Services.AddHttpContextAccessor(); // Needed for CoreSignatureVerifier

// Memoria thread-safe para Nonces usados (Prevención de Replay Attack)
builder.Services.AddSingleton<ConcurrentDictionary<string, DateTime>>();

// Entity Framework Core Context
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

// Registro de Repositorios y Servicios de Infraestructura
builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
builder.Services.AddScoped<IAdEventRepository, AdEventRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
builder.Services.AddSingleton<ICoreSignatureVerifier, CoreSignatureVerifier>();
builder.Services.AddScoped<IMarketingBrainService, MarketingBrainClient>();

// Servicios de la Capa de Aplicación
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<EventProcessingService>();
builder.Services.AddScoped<MetricsService>();
builder.Services.AddScoped<BudgetService>();

var app = builder.Build();

// Asegurar la creación de tablas en SQLite al arrancar.
// NOTA: En un entorno de producción real, se usarían migraciones.
using (var scope = app.Services.CreateScope())
{
    var dataDir = Path.Combine(builder.Environment.ContentRootPath, "App_Data");
    Directory.CreateDirectory(dataDir);

    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

if (app.Environment.IsDevelopment() || app.Environment.IsProduction())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();
app.MapControllers();

app.Run();
