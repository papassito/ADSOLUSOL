namespace ADSOLUSOL.Domain.Interfaces;

public interface IMarketingBrainService
{
    Task<bool> PingAsync();
    Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0m);
}
