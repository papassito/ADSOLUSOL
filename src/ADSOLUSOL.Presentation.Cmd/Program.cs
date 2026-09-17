﻿using System.Collections.Concurrent;
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

// La lógica del comando se ejecutaría aquí, resolviendo servicios desde host.Services
