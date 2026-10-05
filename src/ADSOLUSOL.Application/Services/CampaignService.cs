using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Application.Services;

public class CampaignService
{
    private readonly ICampaignRepository _campaignRepository;
    private readonly IUnitOfWork _unitOfWork;

    public CampaignService(ICampaignRepository campaignRepository, IUnitOfWork unitOfWork)
    {
        _campaignRepository = campaignRepository;
        _unitOfWork = unitOfWork;
    }

    public Task<IEnumerable<Campaign>> ListAsync(string tenantId, CancellationToken token = default)
    {
        return _campaignRepository.GetAllAsync(tenantId, token);
    }

    public async Task<Campaign?> GetAsync(string tenantId, string id, CancellationToken token = default)
    {
        if (Guid.TryParse(id, out _)) // Validate that the ID is a valid GUID string
        {
            var campaign = await _campaignRepository.GetByIdAsync(id);
            return (campaign?.TenantId == tenantId) ? campaign : null;
        }
        return null;
    }

    public async Task<Campaign> CreateAsync(string tenantId, string name, decimal budget, decimal cpm, decimal cpc, DateTime? startDate, DateTime? endDate, CancellationToken token = default)
    {
        var effectiveStartDate = startDate ?? DateTime.UtcNow;

        // A campaign starting in the future should be scheduled, otherwise it's paused by default.
        var initialStatus = (effectiveStartDate > DateTime.UtcNow) ? "SCHEDULED" : "PAUSED";

        var campaign = new Campaign
        {
            Id = Guid.NewGuid().ToString(),
            TenantId = tenantId,
            Name = name,
            Budget = budget,
            Status = initialStatus,
            CreatedAtUtc = DateTime.UtcNow,
            CostPerMille = cpm,
            CostPerClick = cpc,
            StartDateUtc = effectiveStartDate,
            EndDateUtc = endDate ?? effectiveStartDate.AddDays(30)
        };
        await _campaignRepository.CreateAsync(campaign);
        await _unitOfWork.SaveChangesAsync(token);
        return campaign;
    }

    public async Task<Campaign?> UpdateStatusAsync(string tenantId, string id, string status)
    {
        var campaign = await _campaignRepository.GetByIdAsync(id);
        if (campaign == null || campaign.TenantId != tenantId)
        {
            return null;
        }

        var targetStatus = status.Trim().ToUpperInvariant();

        // Validación de máquina de estados y control de transición
        var isAllowedTransition = campaign.Status switch
        {
            "SCHEDULED" => targetStatus is "ACTIVE" or "PAUSED" or "COMPLETED",
            "ACTIVE"    => targetStatus is "PAUSED" or "COMPLETED",
            "PAUSED"    => targetStatus is "ACTIVE" or "COMPLETED",
            "COMPLETED" => false, // Estado terminal
            _           => true
        };

        if (!isAllowedTransition && campaign.Status != targetStatus)
        {
            return null;
        }

        campaign.Status = targetStatus;
        await _campaignRepository.UpdateAsync(campaign);
        await _unitOfWork.SaveChangesAsync();
        return campaign;
    }
}
