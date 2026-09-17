using ADSOLUSOL.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace ADSOLUSOL.Infrastructure.Persistence
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        // DbSets used by repositories
        public DbSet<AdEvent> AdEvents { get; set; }
        public DbSet<CampaignPlacement> CampaignPlacements { get; set; }
        public DbSet<CampaignCreative> CampaignCreatives { get; set; }
        // Other entities like Campaign, Placement, Creative are handled by Dapper repositories,
        // but their tables must exist in the schema. EF can be used to define the schema
        // without managing all data operations for them.

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // FIX P1-04: Add a unique constraint to EventId to guarantee idempotency at the database level.
            modelBuilder.Entity<AdEvent>()
                .HasIndex(e => e.EventId)
                .IsUnique();
            
            modelBuilder.Entity<CampaignPlacement>().HasKey(cp => new { cp.CampaignId, cp.PlacementId });
            modelBuilder.Entity<CampaignCreative>().HasKey(cc => new { cc.CampaignId, cc.CreativeId });
        }
    }
}