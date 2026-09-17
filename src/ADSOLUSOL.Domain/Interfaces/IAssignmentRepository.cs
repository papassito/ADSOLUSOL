namespace ADSOLUSOL.Domain.Interfaces;

public interface IAssignmentRepository
{
    Task AssignCreativeToCampaignAsync(string campaignId, long creativeId);
    Task AssignPlacementToCampaignAsync(string campaignId, long placementId);
}
