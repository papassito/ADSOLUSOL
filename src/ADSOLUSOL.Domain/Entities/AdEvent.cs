namespace ADSOLUSOL.Domain.Entities;

public class AdEvent
{
    public string EventId { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty; // "IMPRESSION" or "CLICK"
    public string CampaignId { get; set; } = string.Empty;
    public long CreativeId { get; set; }
    public string PlacementCode { get; set; } = string.Empty;
    public DateTime OccurredAt { get; set; }
    public DateTime ReceivedAt { get; set; }
}