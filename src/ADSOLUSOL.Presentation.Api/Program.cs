using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Presentation.Api.Middleware;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Data;
using ADSOLUSOL.Infrastructure.Repositories;
using ADSOLUSOL.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// =================================================================
//  CONFIGURACIÓN DE INYECCIÓN DE DEPENDENCIAS (DI)
// =================================================================

// --- REPOSITORIOS (Capa de Acceso a Datos)
builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
builder.Services.AddScoped<IAdEventRepository, AdEventRepository>(); // FIX: Registrado repositorio de eventos faltante.
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>(); // FIX: Registrada la Unidad de Trabajo faltante.

// --- SERVICIOS DE APLICACIÓN (Capa de Lógica de Negocio)
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<IBudgetService, BudgetService>(); // FIX: Registrado servicio de presupuesto.
builder.Services.AddScoped<IEventProcessingService, EventProcessingService>(); // FIX: Registrado servicio de procesamiento de eventos.
builder.Services.AddScoped<ICampaignService, CampaignService>(); // FIX: Registrado servicio de campañas.
builder.Services.AddScoped<IMetricsService, MetricsService>(); // FIX: Registrado servicio de métricas.

// --- SERVICIOS DE INFRAESTRUCTURA (Integraciones Externas, etc.)
builder.Services.AddScoped<ICoreSignatureVerifier, CoreSignatureVerifier>();
builder.Services.AddScoped<IMarketingBrainService, MarketingBrainClient>(); // FIX: Registrado cliente de Marketing Brain.

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// FIX: Conectar el middleware de verificación de firmas en el pipeline.
app.UseMiddleware<SignatureVerificationMiddleware>();

app.UseAuthorization();
app.MapControllers();

app.Run();