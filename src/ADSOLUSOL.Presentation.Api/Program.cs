using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Repositories;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Infrastructure.Security;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Presentation.Api.Middleware;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// --- FASE 2 & 3: Registro de Inyección de Dependencias ---

// Registrar el verificador de firmas como un servicio Scoped
builder.Services.AddScoped<ICoreSignatureVerifier, CoreSignatureVerifier>();

// Registrar los repositorios para que puedan ser inyectados en los servicios de aplicación
builder.Services.AddScoped<IAdEventRepository, AdEventRepository>();
builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();

// Registrar el cliente HTTP para el MarketingBrain (motor Go)
builder.Services.AddHttpClient<IMarketingBrainService, MarketingBrainClient>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["SicService:BaseUrl"] ?? "http://127.0.0.1:8080/");
});

// Registrar los servicios de la capa de aplicación
builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<MetricsService>();
builder.Services.AddScoped<EventProcessingService>();

// Registrar el DbContext para que esté disponible para los repositorios
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// --- FASE 3: Añadir el Middleware de Verificación de Firmas ---
// Este middleware protegerá todos los endpoints que requieran autenticación SOLUSOL_AUTH_V1.
app.UseWhen(context => context.Request.Path.StartsWithSegments("/api/marketing/adsolusol"),
    appBuilder =>
    {
        appBuilder.UseMiddleware<SignatureVerificationMiddleware>();
    });

app.UseAuthorization();

app.MapControllers();

app.Run();