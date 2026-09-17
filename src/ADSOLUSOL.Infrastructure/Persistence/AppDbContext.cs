﻿using Microsoft.EntityFrameworkCore;
using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Campaign> Campaigns { get; set; } = null!;
    public DbSet<AdEvent> AdEvents { get; set; } = null!;

    public async Task<Campaign?> GetCampaignByIdAsync(Guid id)
    {
        // Linea 64 corregida: Comparación explícita de string vs string (.ToString())
        return await Campaigns.FirstOrDefaultAsync(c => c.Id == id.ToString());
    }

    public async Task<Campaign> CreateCampaignAsync(string tenantId, string name, decimal budget)
    {
        var campaign = new Campaign
        {
            // Linea 115 corregida: Conversión explícita de Guid a string
            Id = Guid.NewGuid().ToString(),
            TenantId = tenantId,
            Name = name,
            Budget = budget,
            Status = "PAUSED",
            CreatedAt = DateTime.UtcNow
        };

        Campaigns.Add(campaign);
        await SaveChangesAsync();
        return campaign;
    }

    public async Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default)
    {
        return await Database.CanConnectAsync(cancellationToken);
    }
}
