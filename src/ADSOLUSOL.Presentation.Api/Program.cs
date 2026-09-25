using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Infrastructure.Security;
using ADSOLUSOL.Presentation.Api.Middleware;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using System.Collections.Concurrent;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Data Source=App_Data/adsolusol.db";

var appDataDir = Path.Combine(builder.Environment.ContentRootPath, "App_Data");
if (!Directory.Exists(appDataDir))
{
    Directory.CreateDirectory(appDataDir);
}

// Configuración de la base de datos de la API
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(connectionString));

// Registro de Repositorios del Dominio
builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
builder.Services.AddScoped<IAdEventRepository, AdEventRepository>();
builder.Services.AddSingleton<ICoreSignatureVerifier, CoreSignatureVerifier>();
builder.Services.AddSingleton(new ConcurrentDictionary<string, DateTime>());
builder.Services.AddSingleton<INodeRegistry, NodeRegistry>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// Registro de Servicios de Aplicación
builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<BudgetService>();
builder.Services.AddScoped<EventProcessingService>();
builder.Services.AddScoped<MetricsService>();

// Integración con Marketing Brain
builder.Services.AddScoped<IMarketingBrainService, MarketingBrainClient>();

// Clientes e infraestructura de soporte
builder.Services.AddHttpClient();
builder.Services.AddMemoryCache();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Consolidación de configuraciones exclusivas de desarrollo
if (app.Environment.IsDevelopment())
{
    using (var scope = app.Services.CreateScope())
    {
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        dbContext.Database.EnsureCreated();
    }

    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<ExceptionMiddleware>();
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseMiddleware<SignatureVerificationMiddleware>();
app.UseAuthorization();
app.MapControllers();

app.Run();