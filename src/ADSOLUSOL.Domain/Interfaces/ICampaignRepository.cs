using ADSOLUSOL.Domain.Entities;
using System.Data;

namespace ADSOLUSOL.Domain.Interfaces;

public interface ICampaignRepository
{
    Task<IEnumerable<Campaign>> GetAllAsync(string tenantId, CancellationToken token = default);
    Task<Campaign?> GetByIdAsync(Guid id);
    Task<Campaign?> GetByIdAsync(string id);
    Task CreateAsync(Campaign campaign);
    Task UpdateAsync(Campaign campaign);
    Task UpdateBudgetAsync(string campaignId, decimal cost, IDbTransaction transaction);
}
