namespace ADSOLUSOL.Domain.Dtos;

public record CampaignMetrics(
    string CampaignId,
    int Impressions,
    int Clicks,
    double Ctr,
    decimal Budget,
    decimal BudgetSpent
);