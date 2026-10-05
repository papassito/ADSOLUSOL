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
        if (string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(placementCode))
        {
            return null;
        }

        var placement = await _placementRepository.GetByCodeAsync(placementCode);
        if (placement == null || !placement.IsEnabled) return null;

        var eligibleCampaigns = await _placementRepository.GetEligibleCampaignsAsync(tenantId, placementCode);

        // Iterar sobre las campañas ordenadas por mayor presupuesto remanente para seleccionar el primer creativo elegible.
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
