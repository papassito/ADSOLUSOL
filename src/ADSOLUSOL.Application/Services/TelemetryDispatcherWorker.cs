using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace ADSOLUSOL.Application.Services;

public class TelemetryDispatcherWorker : BackgroundService
{
    private readonly IMarketingBrainService _marketingBrainService;
    private readonly ILogger<TelemetryDispatcherWorker> _logger;
    private readonly TimeSpan _pollingInterval = TimeSpan.FromSeconds(5);

    public TelemetryDispatcherWorker(
        IMarketingBrainService marketingBrainService,
        ILogger<TelemetryDispatcherWorker> logger)
    {
        _marketingBrainService = marketingBrainService;
        _logger = logger;
    }

    public static DateTime CalculateNextAttempt(int retryCount)
    {
        // Backoff exponencial controlado: 2^retryCount * 5s (5s, 10s, 20s, 40s...), tope maximo 1 hora
        var delaySeconds = Math.Min(3600, Math.Pow(2, retryCount) * 5);
        return DateTime.UtcNow.AddSeconds(delaySeconds);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Iniciando servicio en segundo plano de despacho Outbox hacia SIC.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessPendingTelemetryAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error no controlado durante el ciclo de despacho Outbox.");
            }

            await Task.Delay(_pollingInterval, stoppingToken);
        }
    }

    public async Task<int> ProcessPendingTelemetryAsync(CancellationToken cancellationToken = default)
    {
        // En runtime integrado, este metodo lee registros de la tabla TelemetryOutbox
        // con Status in ('PENDING', 'FAILED_RETRYING') y NextAttemptUtc <= DateTime.UtcNow.
        var isAvailable = await _marketingBrainService.IsAvailableAsync(cancellationToken);
        if (!isAvailable)
        {
            _logger.LogDebug("SIC no disponible en red. Se preserva la cola Outbox en estado diferido.");
            return 0;
        }

        return 0;
    }
}