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

    public async Task<bool> DebitEventCost(string campaignId, decimal cost, IDbTransaction transaction)
    {
        if (cost > 0)
        {
            // UpdateBudgetAsync now returns the number of affected rows.
            // If 0, it means the budget would be exceeded, and the update was blocked.
            var rowsAffected = await _campaignRepository.UpdateBudgetAsync(campaignId, cost, transaction);
            return rowsAffected > 0;
        }

        // If cost is zero, the debit is trivially successful.
        return true;
    }
}
