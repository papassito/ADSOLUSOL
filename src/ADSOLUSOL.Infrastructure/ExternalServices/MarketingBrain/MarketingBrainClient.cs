using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;

public class MarketingBrainClient : IMarketingBrainService
{
    public Task<bool> PingAsync() => Task.FromResult(true);

    public Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0m)
    {
        return Task.CompletedTask;
    }
}
