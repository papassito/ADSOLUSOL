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

        var eligibleCampaigns = await _placementRepository.GetEligibleCampaignsAsync(placementCode);
        var now = DateTime.UtcNow;

        var validCampaigns = eligibleCampaigns
            // Correct logic: campaign is active, within date range, and has budget
            .Where(c => c.Status == "ACTIVE" && c.StartDateUtc <= now && c.EndDateUtc >= now && c.RemainingBudget > 0)
            .OrderBy(_ => Guid.NewGuid())
            .ToList();

        foreach (var campaign in validCampaigns)
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
