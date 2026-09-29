using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Infrastructure.Security;
using ADSOLUSOL.Presentation.Api.Middleware;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.HttpOverrides;
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

// --- CONFIGURACIÓN PARA PRODUCCIÓN ---
// 1. Política CORS para permitir peticiones desde el frontend web
builder.Services.AddCors(options =>
{
    options.AddPolicy("ProductionCorsPolicy", policy =>
    {
        policy.WithOrigins("https://adsolusol.solusol.net")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// 2. Configuración para operar detrás de un reverse proxy (Nginx, IIS, etc.)
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    // Limpiar redes y proxies por defecto para permitir cabeceras forwarded desde el proxy inverso
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

var app = builder.Build();

// Inicialización de esquema SQLite en desarrollo o cuando se solicite por configuración/entorno
var shouldInitSchema = app.Environment.IsDevelopment()
    || string.Equals(Environment.GetEnvironmentVariable("INIT_SQLITE_SCHEMA"), "true", StringComparison.OrdinalIgnoreCase)
    || builder.Configuration.GetValue<bool>("INIT_SQLITE_SCHEMA");

if (shouldInitSchema)
{
    using (var scope = app.Services.CreateScope())
    {
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        dbContext.Database.EnsureCreated();
    }
}

// El middleware de ForwardedHeaders debe ir antes de redirecciones o autenticación
app.UseForwardedHeaders();

app.UseSwagger();
app.UseSwaggerUI();

if (!app.Environment.IsDevelopment())
{
    app.UseCors("ProductionCorsPolicy");
}

// Liveness check básico previo al middleware de firma
app.Use(async (context, next) =>
{
    if (context.Request.Path.Equals("/api/health", StringComparison.OrdinalIgnoreCase))
    {
        await next();
        return;
    }
    if (context.Request.Path.Equals("/health", StringComparison.OrdinalIgnoreCase))
    {
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { status = "Healthy", timestamp = DateTime.UtcNow });
        return;
    }
    await next();
});

// Redirigir la raíz a Swagger o mostrar información básica de la API
app.MapGet("/", () => Results.Redirect("/swagger"));

app.UseMiddleware<ExceptionMiddleware>();
app.UseMiddleware<SignatureVerificationMiddleware>();
app.UseAuthorization();
app.MapControllers();

app.Run();