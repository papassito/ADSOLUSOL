using ADSOLUSOL.Domain.Entities;
using System.Data;

namespace ADSOLUSOL.Domain.Repositories;

public interface IAdEventRepository
{
    Task<bool> ExistsAsync(string eventId);
    Task AddAsync(AdEvent adEvent, IDbTransaction transaction);
    Task<int> CountByTypeAsync(string campaignId, string eventType);
}