using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace ADSOLUSOL.Presentation.Api.Health;

public sealed class PersistenceHealthCheck(AppDbContext storage) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
        => await storage.IsAvailableAsync(cancellationToken)
            ? HealthCheckResult.Healthy()
            : HealthCheckResult.Unhealthy("SQLite storage is not accessible.");
}

public sealed class MarketingBrainHealthCheck(IMarketingBrainService brainService) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        if (brainService is not MarketingBrainClient brain)
        {
            return HealthCheckResult.Unhealthy("MarketingBrainService is not a resolvable MarketingBrainClient instance.");
        }

        return await brain.IsAvailableAsync(cancellationToken)
            ? HealthCheckResult.Healthy() : HealthCheckResult.Unhealthy("SIC content integration is not configured or unavailable.");
    }
}
