using System;

namespace ADSOLUSOL.Domain.Entities
{
    public class Campaign
    {
        // Propiedades Core de Compatibilidad
        public string Id { get; set; } = string.Empty;
        public string TenantId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public decimal Budget { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Propiedades Extendidas del Advertising Engine
        public string AdvertiserId { get; set; } = string.Empty;
        public string PlacementId { get; set; } = string.Empty;
        public DateTime StartDateUtc { get; set; } = DateTime.UtcNow;
        public DateTime EndDateUtc { get; set; } = DateTime.UtcNow.AddDays(30);
        public string TargetUrl { get; set; } = string.Empty;
        public string BannerUrl { get; set; } = string.Empty;
        
        // Métricas y Monetización
        public string PricingModel { get; set; } = "CPC";
        public decimal Rate { get; set; }
        public decimal BudgetTotal { get; set; }
        public decimal BudgetSpent { get; set; }
        public long TotalImpressions { get; set; }
        public long TotalClicks { get; set; }
        public double Ctr => TotalImpressions == 0 ? 0.0 : (double)TotalClicks / TotalImpressions;
        public string Status { get; set; } = "ACTIVE";
    }
}