using ADSOLUSOL.Domain.Entities;
using System.Data;

namespace ADSOLUSOL.Domain.Interfaces;

public interface ICampaignRepository
{
    Task CreateAsync(Campaign campaign);
    Task<IEnumerable<Campaign>> GetAllAsync(string tenantId, CancellationToken token = default);
    Task<Campaign?> GetByIdAsync(string id);
    Task UpdateAsync(Campaign campaign);
    Task<int> UpdateBudgetAsync(string campaignId, decimal cost, IDbTransaction transaction);
    Task<bool> IsPlacementAssociatedAsync(string campaignId, long placementId);
    Task<bool> IsCreativeAssociatedAsync(string campaignId, long creativeId);
}
