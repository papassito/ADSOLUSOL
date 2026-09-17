using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Presentation.Api.Middleware;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// FIX: Re-add DbContext configuration.
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection"));
});

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
// FIX: Register concrete service classes as interfaces are not defined for them yet.
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<BudgetService>();
builder.Services.AddScoped<EventProcessingService>();
builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<MetricsService>();

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

// Add Exception Middleware at the top of the pipeline
app.UseMiddleware<ExceptionMiddleware>();

app.UseHttpsRedirection();

// FIX: Conectar el middleware de verificación de firmas en el pipeline.
app.UseMiddleware<SignatureVerificationMiddleware>();

// FIX: Ensure the database schema is created on startup.
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var dbContext = services.GetRequiredService<AppDbContext>();
    dbContext.Database.EnsureCreated();
}

app.UseAuthorization();
app.MapControllers();

app.Run();