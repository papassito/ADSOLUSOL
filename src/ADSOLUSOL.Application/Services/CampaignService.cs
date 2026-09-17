using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Application.Services;

public class CampaignService
{
    private readonly ICampaignRepository _campaignRepository;

    public CampaignService(ICampaignRepository campaignRepository)
    {
        _campaignRepository = campaignRepository;
    }

    public Task<IEnumerable<Campaign>> ListAsync(string tenantId, CancellationToken token = default)
    {
        return _campaignRepository.GetAllAsync(tenantId, token);
    }

    public async Task<Campaign?> GetAsync(string tenantId, string id, CancellationToken token = default)
    {
        if (Guid.TryParse(id, out var campaignGuid))
        {
            var campaign = await _campaignRepository.GetByIdAsync(campaignGuid);
            return (campaign?.TenantId == tenantId) ? campaign : null;
        }
        return null;
    }

    public async Task<Campaign> CreateAsync(string tenantId, string name, decimal budget, CancellationToken token = default)
    {
        var campaign = new Campaign
        {
            Id = Guid.NewGuid().ToString(),
            TenantId = tenantId,
            Name = name,
            Budget = budget,
            Status = "PAUSED",
            CreatedAt = DateTime.UtcNow
        };
        await _campaignRepository.CreateAsync(campaign);
        return campaign;
    }

    public async Task<Campaign?> UpdateStatusAsync(string tenantId, string id, string status)
    {
        if (!Guid.TryParse(id, out var campaignGuid))
        {
            return null;
        }

        var campaign = await _campaignRepository.GetByIdAsync(campaignGuid);
        if (campaign == null || campaign.TenantId != tenantId)
        {
            return null;
        }

        campaign.Status = status;
        await _campaignRepository.UpdateAsync(campaign);
        return campaign;
    }
}
