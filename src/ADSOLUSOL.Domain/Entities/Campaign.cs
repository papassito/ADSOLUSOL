namespace ADSOLUSOL.Domain.Entities;

public class Campaign
{
    public string Id { get; set; } = string.Empty;
    public string TenantId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = "Active";
    public decimal Budget { get; set; }
    public decimal BudgetSpent { get; set; }
    public decimal RemainingBudget { get; set; }
    public decimal CostPerMille { get; set; }
    public decimal CostPerClick { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime StartDateUtc { get; set; }
    public DateTime? EndDateUtc { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
