using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();

// Entity Framework Core Context
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

// Inyección de Repositorios de Infraestructura
builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();

// Servicios de Aplicación
builder.Services.AddScoped<AdServingService>();

var app = builder.Build();

if (app.Environment.IsDevelopment() || app.Environment.IsProduction())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();
app.MapControllers();

app.Run();
