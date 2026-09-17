using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Application.Interfaces;

public interface IAppDbContext
{
    void AddCampaign(Campaign campaign);
    Task<IReadOnlyList<Campaign>> GetCampaignsAsync(string tenantId, CancellationToken cancellationToken = default);
    Task<Campaign?> GetCampaignAsync(string tenantId, Guid id, CancellationToken cancellationToken = default);
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
