using System.Collections.Concurrent;
using ADSOLUSOL.Presentation.Cmd.Commands;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Security;
using ADSOLUSOL.Infrastructure.Repositories;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

Console.WriteLine("ADSOLUSOL CLI Command Runner");

using IHost host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        // Registrar dependencias para CoreSignatureVerifier según instrucción
        services.AddSingleton<ConcurrentDictionary<string, DateTime>>();
        services.AddSingleton<ICoreSignatureVerifier, CoreSignatureVerifier>();
    })
    .Build();

Console.WriteLine("DI Host initialized successfully.");

var commandArg = args.Length > 0 ? args[0].ToLowerInvariant() : "help";

switch (commandArg)
{
    case "start-engine":
        new StartEngineCommand().Execute();
        break;
    case "sync-campaigns":
        new SyncCampaignsCommand().Execute();
        break;
    default:
        Console.WriteLine("Comandos disponibles: start-engine, sync-campaigns");
        break;
}
