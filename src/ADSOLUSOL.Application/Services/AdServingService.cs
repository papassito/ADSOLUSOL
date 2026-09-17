using ADSOLUSOL.Domain.Repositories;

namespace ADSOLUSOL.Application.Services;

public record AdDecision(string CampaignId, long CreativeId, string ContentUrl, string TargetUrl);

public class AdServingService
{
    private readonly IPlacementRepository _placementRepository;
    private readonly ICreativeRepository _creativeRepository;

    public AdServingService(IPlacementRepository placementRepository, ICreativeRepository creativeRepository)
    {
        _placementRepository = placementRepository;
        _creativeRepository = creativeRepository;
    }

    public async Task<AdDecision?> SelectAdForPlacement(string placementCode)
    {
        // 1. Find the placement
        var placement = await _placementRepository.GetByCodeAsync(placementCode);
        if (placement == null)
        {
            return null; // No such placement or it's disabled
        }

        // 2. Find eligible campaigns for this placement
        // The repository query already filters by ACTIVE status and budget > 0
        var eligibleCampaigns = (await _placementRepository.GetEligibleCampaignsAsync(placement.Id));

        if (!eligibleCampaigns.Any())
        {
            return null; // No active campaigns with budget for this placement
        }

        // 3. Filter campaigns by date range (vigencia) and shuffle for fairness
        var now = DateTime.UtcNow;
        var validCampaigns = eligibleCampaigns
            .Where(c => (c.StartDateUtc == null || c.StartDateUtc <= now) && (c.EndDateUtc == null || c.EndDateUtc >= now))
            .OrderBy(c => Guid.NewGuid()) // Simple randomization for fair selection
            .ToList();

        if (!validCampaigns.Any())
        {
            return null; // No campaigns currently active by date
        }

        // 4. Select a campaign (simple rotation for now) and find a creative
        foreach (var campaign in validCampaigns)
        {
            var creative = await _creativeRepository.GetEligibleCreativeForCampaignAsync(campaign.Id);
            if (creative != null)
            {
                return new AdDecision(campaign.Id, creative.Id, creative.ContentUrl, creative.TargetUrl);
            }
        }

        return null; // No eligible creatives found for any valid campaign
    }
}