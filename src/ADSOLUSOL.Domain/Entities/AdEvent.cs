namespace ADSOLUSOL.Domain.Entities;

public class AdEvent
{
    public string Id { get; set; } = string.Empty;
    public string EventId { get; set; } = string.Empty;
    public string CampaignId { get; set; } = string.Empty;
    public string CreativeId { get; set; } = string.Empty;
    public string PlacementId { get; set; } = string.Empty;
    public string PlacementCode { get; set; } = string.Empty;
    public string TenantId { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty;
    public decimal Cost { get; set; }
    public DateTime TimestampUtc { get; set; } = DateTime.UtcNow;
    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
    public DateTime ReceivedAt { get; set; } = DateTime.UtcNow;
    public string IPAddress { get; set; } = string.Empty;
    public string UserAgent { get; set; } = string.Empty;
}
