namespace ADSOLUSOL.Domain.Entities;

public class Placement
{
    public long Id { get; set; }
    public string PlacementCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public bool IsEnabled { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}