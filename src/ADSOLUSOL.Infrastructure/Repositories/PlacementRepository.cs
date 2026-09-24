using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Dapper;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class PlacementRepository : IPlacementRepository
{
    private readonly AppDbContext _context;

    public PlacementRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Placement?> GetByCodeAsync(string code)
    {
        return await _context.Placements
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.PlacementCode == code);
    }

    public async Task<IEnumerable<Campaign>> GetEligibleCampaignsAsync(string tenantId, string placementCode)
    {
        var connection = _context.Database.GetDbConnection();
        var now = DateTime.UtcNow;
        var sql = @"
            SELECT c.* FROM Campaigns c
            INNER JOIN CampaignPlacements cp ON c.Id = cp.CampaignId
            INNER JOIN Placements p ON cp.PlacementId = p.Id
            WHERE p.PlacementCode = @PlacementCode
              AND p.IsEnabled = 1
              AND c.TenantId = @TenantId 
              AND c.Status = 'ACTIVE' 
              AND CAST(c.Budget AS REAL) > CAST(c.BudgetSpent AS REAL)
              AND c.StartDateUtc <= @Now AND c.EndDateUtc >= @Now
            ORDER BY (CAST(c.Budget AS REAL) - CAST(c.BudgetSpent AS REAL)) DESC, c.CreatedAtUtc ASC;";
        return await connection.QueryAsync<Campaign>(sql, new { TenantId = tenantId, PlacementCode = placementCode, Now = now });
    }

    public async Task<long> CreateAsync(Placement placement)
    {
        await _context.Placements.AddAsync(placement);
        await _context.SaveChangesAsync();
        return placement.Id;
    }

    public async Task<IEnumerable<Placement>> GetAllAsync()
    {
        return await _context.Placements
            .AsNoTracking()
            .ToListAsync();
    }
}
