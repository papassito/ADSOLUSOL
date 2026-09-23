using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Security;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace ADSOLUSOL.Presentation.Desktop;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>()
            .ConfigureFonts(fonts =>
            {
                fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
            });

        builder.Services.AddMauiBlazorWebView();

#if DEBUG
        builder.Services.AddBlazorWebViewDeveloperTools();
        builder.Logging.AddDebug();
#endif
        // Configuración de la base de datos SQLite en el directorio local
        var dbPath = Path.Combine(FileSystem.AppDataDirectory, "adsolusol.db");
        builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlite($"Data Source={dbPath}"));

        // Registro de capas de persistencia y repositorios
        builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
        builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
        builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
        builder.Services.AddScoped<IAdEventRepository, AdEventRepository>();
        builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
        builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Registro de servicios del dominio y aplicación
        builder.Services.AddScoped<CampaignService>();
        builder.Services.AddScoped<EventProcessingService>();
        builder.Services.AddScoped<BudgetService>();
        builder.Services.AddScoped<MetricsService>();
        builder.Services.AddScoped<AdServingService>();

        return builder.Build();
    }
}