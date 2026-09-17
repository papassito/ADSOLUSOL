using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Dtos;
using ADSOLUSOL.Domain.Enums;
using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Application.Services;

public class MetricsService
{
    private readonly ICampaignRepository _campaignRepository;
    private readonly IAdEventRepository _eventRepository;

    public MetricsService(ICampaignRepository campaignRepository, IAdEventRepository eventRepository)
    {
        _campaignRepository = campaignRepository;
        _eventRepository = eventRepository;
    }

    public async Task<CampaignMetrics?> GetMetricsForCampaign(string campaignId)
    {
        var campaign = await _campaignRepository.GetByIdAsync(campaignId);
        if (campaign is null) return null;

        var impressions = await _eventRepository.CountByTypeAsync(campaignId, EventType.Impression.ToString().ToUpper());
        var clicks = await _eventRepository.CountByTypeAsync(campaignId, EventType.Click.ToString().ToUpper());

        double ctr = (impressions > 0) ? (double)clicks / impressions * 100.0 : 0.0;

        return new CampaignMetrics(
            campaign.Id,
            impressions,
            clicks,
            Math.Round(ctr, 2),
            campaign.Budget,
            campaign.BudgetSpent
        );
    }
}

