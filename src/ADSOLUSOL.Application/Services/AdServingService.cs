using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Application.Services;

public class AdServingService
{
    private readonly IPlacementRepository _placementRepository;
    private readonly ICreativeRepository _creativeRepository;

    public AdServingService(IPlacementRepository placementRepository, ICreativeRepository creativeRepository)
    {
        _placementRepository = placementRepository;
        _creativeRepository = creativeRepository;
    }

    public async Task<Creative?> SelectAdForPlacement(string tenantId, string placementCode)
    {
        var placement = await _placementRepository.GetByCodeAsync(placementCode);
        if (placement == null) return null;

        var eligibleCampaigns = await _placementRepository.GetEligibleCampaignsAsync(tenantId, placementCode);

        // The repository now returns campaigns in a random order. Iterate directly to save memory.
        foreach (var campaign in eligibleCampaigns)
        {
            var creative = await _creativeRepository.GetEligibleCreativeForCampaignAsync(campaign.Id);
            if (creative != null)
            {
                return creative;
            }
        }

        return null;
    }
}
