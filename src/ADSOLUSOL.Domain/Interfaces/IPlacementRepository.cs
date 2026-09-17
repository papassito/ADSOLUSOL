using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IPlacementRepository
{
    Task<Placement?> GetByCodeAsync(string code);
    Task<IEnumerable<Campaign>> GetEligibleCampaignsAsync(string placementCode);
    Task<long> CreateAsync(Placement placement);
    Task<IEnumerable<Placement>> GetAllAsync();
}
