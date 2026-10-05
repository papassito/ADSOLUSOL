namespace ADSOLUSOL.Domain.Entities;

public enum TelemetryOutboxStatus
{
    PENDING,
    DISPATCHED,
    FAILED_RETRYING,
    ABANDONED
}

public class TelemetryOutbox
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string CampaignId { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty;
    public decimal Cost { get; set; }
    public string PayloadJson { get; set; } = string.Empty;
    public string Status { get; set; } = nameof(TelemetryOutboxStatus.PENDING);
    public int RetryCount { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime NextAttemptUtc { get; set; } = DateTime.UtcNow;
    public string? LastError { get; set; }
}