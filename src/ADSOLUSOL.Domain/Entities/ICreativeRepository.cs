using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Domain.Repositories;

public interface ICreativeRepository
{
    Task<long> CreateAsync(Creative creative);
    Task<Creative?> GetByIdAsync(long creativeId);
    Task<Creative?> GetEligibleCreativeForCampaignAsync(string campaignId);
}