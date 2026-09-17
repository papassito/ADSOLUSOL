namespace ADSOLUSOL.Domain.Interfaces;

public interface IPlacementRepository
{
    Task<Entities.Placement?> GetByCodeAsync(string code);
    Task<IEnumerable<Entities.Campaign>> GetEligibleCampaignsAsync(long placementId);
    Task<IEnumerable<Entities.Campaign>> GetEligibleCampaignsAsync(string placementCode);
}
