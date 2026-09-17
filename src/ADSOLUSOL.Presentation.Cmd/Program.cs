using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Presentation.Api.Security;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace ADSOLUSOL.Presentation.Cmd;

class Program
{
    static async Task Main(string[] args)
    {
        var host = Host.CreateDefaultBuilder(args)
            .ConfigureServices((context, services) =>
            {
                services.AddScoped<CoreSignatureVerifier>();
                services.AddHttpClient<IMarketingBrainService, MarketingBrainClient>((serviceProvider, client) =>
                {
                    var configuration = serviceProvider.GetRequiredService<IConfiguration>();
                    client.BaseAddress = new Uri(configuration["SolusolAuthV1:SicBaseUrl"] ?? "http://127.0.0.1:8080");
                });
            })
            .Build();

        Console.WriteLine("ADSOLUSOL CLI Running.");
        Console.WriteLine("Resolving services from DI container...");

        var verifier = host.Services.GetService<CoreSignatureVerifier>();
        var brain = host.Services.GetService<IMarketingBrainService>();

        Console.WriteLine(verifier != null ? "CoreSignatureVerifier resolved." : "Failed to resolve CoreSignatureVerifier.");
        Console.WriteLine(brain != null ? "IMarketingBrainService resolved." : "Failed to resolve IMarketingBrainService.");

        // The host can be used to run background services or commands.
        // For this example, we just demonstrate DI resolution.
        await Task.CompletedTask;
    }
}
