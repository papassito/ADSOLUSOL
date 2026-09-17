using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using System.Data;
using ADSOLUSOL.Domain.Enums;

namespace ADSOLUSOL.Application.Services;

public class BudgetService
{
    private readonly ICampaignRepository _campaignRepository;

    public BudgetService(ICampaignRepository campaignRepository)
    {
        _campaignRepository = campaignRepository;
    }

    public async Task<bool> DebitEventCost(string campaignId, EventType eventType, IDbTransaction transaction, Domain.Entities.Campaign? campaign = null)
    {
        // Allow passing the campaign object to avoid an extra DB query within the transaction.
        campaign ??= await _campaignRepository.GetByIdAsync(campaignId);
        if (campaign is null)
        {
            // Campaign not found, cannot debit. Consider this a failure.
            return false;
        }

        decimal cost = eventType switch
        {
            EventType.Impression => campaign.CostPerMille / 1000,
            EventType.Click => campaign.CostPerClick,
            _ => 0
        };

        if (cost > 0)
        {
            // UpdateBudgetAsync now returns the number of affected rows.
            // If 0, it means the budget would be exceeded, and the update was blocked.
            var rowsAffected = await _campaignRepository.UpdateBudgetAsync(campaign.Id, cost, transaction);
            return rowsAffected > 0;
        }
        
        // If cost is zero, the debit is trivially successful.
        return true;
    }
}
