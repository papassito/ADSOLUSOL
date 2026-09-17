using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Domain.Interfaces;

public interface ICreativeRepository
{
    Task<Creative?> GetEligibleCreativeForCampaignAsync(string campaignId);
    Task<Creative?> GetByIdAsync(long id);
    Task<long> CreateAsync(Creative creative);
}
