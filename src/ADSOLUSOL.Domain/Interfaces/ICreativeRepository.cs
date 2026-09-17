namespace ADSOLUSOL.Domain.Interfaces;

public interface ICreativeRepository
{
    Task<Entities.Creative?> GetEligibleCreativeForCampaignAsync(string campaignId);
    Task<Entities.Creative?> GetEligibleCreativeForCampaignAsync(Guid campaignId);
}
