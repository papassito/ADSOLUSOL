using Microsoft.EntityFrameworkCore;
using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Campaign> Campaigns => Set<Campaign>();
    public DbSet<Placement> Placements => Set<Placement>();
    public DbSet<Creative> Creatives => Set<Creative>();
    public DbSet<AdEvent> AdEvents => Set<AdEvent>();
    public DbSet<CampaignPlacement> CampaignPlacements => Set<CampaignPlacement>();
    public DbSet<CampaignCreative> CampaignCreatives => Set<CampaignCreative>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Campaign>().HasKey(c => c.Id);
        modelBuilder.Entity<Placement>().HasKey(p => p.Id);
        modelBuilder.Entity<Creative>().HasKey(c => c.Id);
        modelBuilder.Entity<AdEvent>().HasKey(e => e.Id);

        // Many-to-many: Campaign <-> Placement
        modelBuilder.Entity<CampaignPlacement>().HasKey(cp => new { cp.CampaignId, cp.PlacementId });

        // Many-to-many: Campaign <-> Creative
        modelBuilder.Entity<CampaignCreative>().HasKey(cc => new { cc.CampaignId, cc.CreativeId });
    }

    public async Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default)
    {
        return await Database.CanConnectAsync(cancellationToken);
    }
}
