using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Application.Services;

public sealed class CampaignService(IAppDbContext context)
{
    public Task<IReadOnlyList<Campaign>> ListAsync(string tenantId, CancellationToken token = default) => context.GetCampaignsAsync(tenantId, token);
    public Task<Campaign?> GetAsync(string tenantId, Guid id, CancellationToken token = default) => context.GetCampaignAsync(tenantId, id, token);

    public async Task<Campaign> CreateAsync(string tenantId, string name, decimal budget, CancellationToken token = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(name);
        var campaign = new Campaign { Id = Guid.NewGuid(), TenantId = tenantId, Name = name.Trim(), Budget = budget };
        context.AddCampaign(campaign);
        await context.SaveChangesAsync(token);
        return campaign;
    }
}
