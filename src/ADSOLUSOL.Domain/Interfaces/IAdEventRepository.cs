using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IAdEventRepository
{
    Task CreateAsync(AdEvent adEvent);
    Task<bool> ExistsAsync(string eventId);
}