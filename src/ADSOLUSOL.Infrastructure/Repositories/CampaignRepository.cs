﻿﻿﻿﻿﻿﻿﻿using ADSOLUSOL.Domain.Entities;
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
        return await _context.Campaigns.FirstOrDefaultAsync(c => c.Id == id);
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
        // FIX: Explicitly CAST to REAL for correct numeric comparison in SQLite, as decimals are stored as TEXT.
        var sql = @"UPDATE Campaigns SET BudgetSpent = BudgetSpent + @Cost 
                    WHERE Id = @CampaignId AND CAST(BudgetSpent AS REAL) + @Cost <= CAST(Budget AS REAL);";
        return await transaction.Connection.ExecuteAsync(sql, new { Cost = cost, CampaignId = campaignId }, transaction);
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
