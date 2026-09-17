using System.ComponentModel.DataAnnotations.Schema;

namespace ADSOLUSOL.Domain.Entities;

public class Campaign
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string TenantId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = "SCHEDULED"; // SCHEDULED, ACTIVE, PAUSED, COMPLETED

    public decimal Budget { get; set; }
    public decimal BudgetSpent { get; set; }

    [NotMapped]
    public decimal RemainingBudget => Budget - BudgetSpent;

    public decimal CostPerMille { get; set; }
    public decimal CostPerClick { get; set; }

    public DateTime StartDateUtc { get; set; }
    public DateTime EndDateUtc { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}