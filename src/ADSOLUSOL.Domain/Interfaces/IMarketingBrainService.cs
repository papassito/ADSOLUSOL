namespace ADSOLUSOL.Domain.Interfaces;

public interface IMarketingBrainService
{
    Task<bool> PingAsync();
}