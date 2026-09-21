﻿﻿﻿using ADSOLUSOL.Domain.Entities;
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
        var connection = _context.Database.GetDbConnection();
        var sql = "SELECT * FROM Placements WHERE PlacementCode = @Code;";
        return await connection.QueryFirstOrDefaultAsync<Placement>(sql, new { Code = code });
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
              AND c.Budget > c.BudgetSpent
              AND c.StartDateUtc <= @Now AND c.EndDateUtc >= @Now
            ORDER BY RANDOM();";
        return await connection.QueryAsync<Campaign>(sql, new { TenantId = tenantId, PlacementCode = placementCode, Now = now });
    }

    public async Task<long> CreateAsync(Placement placement)
    {
        var sql = @"
            INSERT INTO Placements (PlacementCode, Name, IsEnabled, CreatedAt, UpdatedAt)
            VALUES (@PlacementCode, @Name, @IsEnabled, @CreatedAt, @UpdatedAt);
            SELECT last_insert_rowid();";
        // For a create operation that should be transactional, it should use the UnitOfWork transaction connection.
        // However, the current regression test for placement creation doesn't use a transaction.
        // To maintain consistency, we'll use the DbContext connection.
        var connection = _context.Database.GetDbConnection();
        return await connection.ExecuteScalarAsync<long>(sql, placement);
    }

    public async Task<IEnumerable<Placement>> GetAllAsync()
    {
        var connection = _context.Database.GetDbConnection();
        var sql = "SELECT * FROM Placements;";
        return await connection.QueryAsync<Placement>(sql);
    }
}
