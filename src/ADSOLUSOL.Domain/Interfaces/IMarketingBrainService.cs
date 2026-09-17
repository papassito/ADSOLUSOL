namespace ADSOLUSOL.Domain.Interfaces;

public interface IMarketingBrainService
{
    Task<bool> PingAsync();
    Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default);
    Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0m);
}
