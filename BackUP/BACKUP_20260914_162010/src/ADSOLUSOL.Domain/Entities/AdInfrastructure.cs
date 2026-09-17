using System;

namespace ADSOLUSOL.Domain.Entities
{
    public class Placement
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int Width { get; set; }
        public int Height { get; set; }
    }

    public class Creative
    {
        public string Id { get; set; } = string.Empty;
        public string CampaignId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string BannerUrl { get; set; } = string.Empty;
        public string TargetUrl { get; set; } = string.Empty;
    }

    public class AdEvent
    {
        public string EventId { get; set; } = string.Empty;
        public string CampaignId { get; set; } = string.Empty;
        public string PlacementId { get; set; } = string.Empty;
        public string EventType { get; set; } = string.Empty; // CLICK, IMPRESSION
        public DateTime TimestampUtc { get; set; }
        public string IPAddress { get; set; } = string.Empty;
        public string UserAgent { get; set; } = string.Empty;
        public decimal Cost { get; set; }
    }

    public class BudgetLedger
    {
        public string Id { get; set; } = string.Empty;
        public string CampaignId { get; set; } = string.Empty;
        public string EventId { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public DateTime TimestampUtc { get; set; }
    }
}