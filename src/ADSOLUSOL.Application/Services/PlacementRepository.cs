using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Repositories;
using Dapper;
using Microsoft.Data.Sqlite;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class PlacementRepository : IPlacementRepository
{
    private readonly string _connectionString;

    public PlacementRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<long> CreateAsync(Placement placement)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = @"
            INSERT INTO Placements (PlacementCode, Name, IsEnabled, CreatedAt, UpdatedAt)
            VALUES (@PlacementCode, @Name, @IsEnabled, @CreatedAt, @UpdatedAt);
            SELECT last_insert_rowid();";
        return await connection.ExecuteScalarAsync<long>(sql, placement);
    }

    public async Task<Placement?> GetByCodeAsync(string placementCode)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = "SELECT * FROM Placements WHERE PlacementCode = @PlacementCode AND IsEnabled = 1;";
        return await connection.QuerySingleOrDefaultAsync<Placement>(sql, new { PlacementCode = placementCode });
    }

    public async Task<IEnumerable<Placement>> GetAllAsync()
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = "SELECT * FROM Placements;";
        return await connection.QueryAsync<Placement>(sql);
    }

    public async Task<IEnumerable<Campaign>> GetEligibleCampaignsAsync(long placementId)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = @"
            SELECT c.* 
            FROM Campaigns c
            JOIN CampaignPlacements cp ON c.Id = cp.CampaignId
            WHERE cp.PlacementId = @PlacementId 
              AND c.Status = 'ACTIVE' 
              AND (c.Budget - c.BudgetSpent) > 0;";
        return await connection.QueryAsync<Campaign>(sql, new { PlacementId = placementId });
    }
}