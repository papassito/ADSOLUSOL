using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Authentication;
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
        // Configurar la base de datos
        var dbPath = Path.Combine(FileSystem.AppDataDirectory, "adsolusol.db");
        builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlite($"Data Source={dbPath}"));

        // Registrar todos los servicios y repositorios reales
        builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
        builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
        builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
        builder.Services.AddScoped<IAdEventRepository, AdEventRepository>();
        builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
        builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
        builder.Services.AddScoped<CampaignService>();
        builder.Services.AddScoped<EventProcessingService>();
        builder.Services.AddScoped<BudgetService>();
        builder.Services.AddScoped<MetricsService>();
        builder.Services.AddScoped<AdServingService>();

        return builder.Build();
    }
}