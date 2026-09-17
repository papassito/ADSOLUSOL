using ADSOLUSOL.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace ADSOLUSOL.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Campaign> Campaigns { get; set; }
    public DbSet<AdEvent> AdEvents { get; set; }
    public DbSet<CampaignPlacement> CampaignPlacements { get; set; }
    public DbSet<CampaignCreative> CampaignCreatives { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<AdEvent>()
            .HasIndex(e => e.EventId)
            .IsUnique();

        modelBuilder.Entity<Campaign>()
            .HasIndex(c => c.TenantId);

        modelBuilder.Entity<CampaignPlacement>().HasKey(cp => new { cp.CampaignId, cp.PlacementId });
        modelBuilder.Entity<CampaignCreative>().HasKey(cc => new { cc.CampaignId, cc.CreativeId });
    }
}
