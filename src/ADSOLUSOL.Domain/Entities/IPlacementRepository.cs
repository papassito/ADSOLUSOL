using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Domain.Repositories;

public interface IPlacementRepository
{
    Task<long> CreateAsync(Placement placement);
    Task<Placement?> GetByCodeAsync(string placementCode);
    Task<IEnumerable<Placement>> GetAllAsync();
    Task<IEnumerable<Campaign>> GetEligibleCampaignsAsync(long placementId);
}