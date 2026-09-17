using ADSOLUSOL.Domain.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IPlacementRepository
{
    Task<Placement?> GetByCodeAsync(string code);
    Task<IEnumerable<Campaign>> GetEligibleCampaignsAsync(string tenantId, string placementCode);
    Task<long> CreateAsync(Placement placement);
    Task<IEnumerable<Placement>> GetAllAsync();
}