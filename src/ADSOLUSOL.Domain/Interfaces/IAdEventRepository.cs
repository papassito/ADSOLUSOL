using System.Data;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IAdEventRepository
{
    Task AddAsync(Entities.AdEvent adEvent, IDbTransaction? transaction = null);
    Task<bool> ExistsAsync(string eventId);
    Task<int> CountByTypeAsync(string campaignId, string eventType);
}
