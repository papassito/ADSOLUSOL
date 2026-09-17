using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Application.Services;

public sealed class CampaignService
{
    private readonly IAppDbContext _context;
    private readonly IMarketingBrainService _marketingBrainService;

    public CampaignService(IAppDbContext context, IMarketingBrainService marketingBrainService)
    {
        _context = context;
        _marketingBrainService = marketingBrainService;
    }

    public Task<IReadOnlyList<Campaign>> ListAsync(string tenantId, CancellationToken token = default) => _context.GetCampaignsAsync(tenantId, token);
    public Task<Campaign?> GetAsync(string tenantId, string id, CancellationToken token = default) => _context.GetCampaignAsync(tenantId, id, token);

    public async Task<Campaign> CreateAsync(string tenantId, string name, decimal budget, CancellationToken token = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);
        var campaign = new Campaign { Id = $"campaign_{Guid.NewGuid():N}", TenantId = tenantId, Name = name.Trim(), Budget = budget, Status = "SCHEDULED" };
        _context.AddCampaign(campaign);
        await _context.SaveChangesAsync(token);
        return campaign;
    }

    public async Task<Campaign?> UpdateStatusAsync(string id, string newStatus)
    {
        var campaign = await _context.GetCampaignAsync("local", id);
        if (campaign is null) return null;

        campaign.Status = newStatus;
        _context.UpdateCampaign(campaign);
        await _context.SaveChangesAsync();

        await _marketingBrainService.EmitTelemetryAsync("CAMPAIGN_STATUS_CHANGED", new { campaign_id = id, new_status = campaign.Status, timestamp = DateTime.UtcNow });

        return campaign;
    }
}
