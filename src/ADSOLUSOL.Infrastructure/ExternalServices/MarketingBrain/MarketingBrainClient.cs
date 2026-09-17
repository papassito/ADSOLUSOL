using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;

public class MarketingBrainClient : IMarketingBrainService
{
    public Task<bool> PingAsync() => Task.FromResult(true);
}