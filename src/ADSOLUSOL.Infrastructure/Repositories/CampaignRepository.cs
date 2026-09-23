using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Dapper;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class CampaignRepository : ICampaignRepository
{
    private readonly AppDbContext _context;

    public CampaignRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task CreateAsync(Campaign campaign)
    {
        // The UnitOfWork is responsible for calling SaveChangesAsync.
        _context.Campaigns.Add(campaign);
        return Task.CompletedTask;
    }

    public async Task<IEnumerable<Campaign>> GetAllAsync(string tenantId, CancellationToken token = default)
    {
        return await _context.Campaigns
            .Where(c => c.TenantId == tenantId)
            .AsNoTracking()
            .ToListAsync(token);
    }

    public async Task<Campaign?> GetByIdAsync(string id)
    {
        var local = _context.Campaigns.Local.FirstOrDefault(c => c.Id == id);
        if (local != null)
        {
            return local;
        }
        return await _context.Campaigns.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);
    }

    public Task UpdateAsync(Campaign campaign)
    {
        // The UnitOfWork is responsible for calling SaveChangesAsync.
        _context.Campaigns.Update(campaign);
        return Task.CompletedTask;
    }

    public async Task<int> UpdateBudgetAsync(string campaignId, decimal cost, IDbTransaction transaction)
    {
        if (transaction.Connection is null)
        {
            throw new InvalidOperationException("The transaction does not have an associated connection.");
        }
        // SQLite almacena tipos decimal como TEXT; se utiliza COALESCE y CAST a REAL para asegurar la suma y comparación numérica
        var sql = @"UPDATE Campaigns 
                    SET BudgetSpent = COALESCE(CAST(BudgetSpent AS REAL), 0) + @Cost 
                    WHERE Id = @CampaignId 
                      AND (COALESCE(CAST(BudgetSpent AS REAL), 0) + @Cost) <= CAST(Budget AS REAL);";
        var rows = await transaction.Connection.ExecuteAsync(sql, new { Cost = (double)cost, CampaignId = campaignId }, transaction);

        var local = _context.Campaigns.Local.FirstOrDefault(c => c.Id == campaignId);
        if (local != null)
        {
            local.BudgetSpent += cost;
            _context.Entry(local).Property(c => c.BudgetSpent).IsModified = false;
        }

        return rows;
    }

    public async Task<bool> IsPlacementAssociatedAsync(string campaignId, long placementId)
    {
        return await _context.CampaignPlacements
            .AnyAsync(cp => cp.CampaignId == campaignId && cp.PlacementId == placementId);
    }

    public async Task<bool> IsCreativeAssociatedAsync(string campaignId, long creativeId)
    {
        return await _context.CampaignCreatives
            .AnyAsync(cc => cc.CampaignId == campaignId && cc.CreativeId == creativeId);
    }
}
