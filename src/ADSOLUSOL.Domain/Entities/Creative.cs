namespace ADSOLUSOL.Domain.Entities;

public class Creative
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ContentUrl { get; set; } = string.Empty; // URL to the image/asset
    public string TargetUrl { get; set; } = string.Empty;  // Click-through URL
    public bool IsEnabled { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}