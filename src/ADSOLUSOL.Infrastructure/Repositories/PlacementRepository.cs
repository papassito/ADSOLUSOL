using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Dapper;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class PlacementRepository : IPlacementRepository
{
    private readonly IConfiguration _configuration;

    public PlacementRepository(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    private IDbConnection CreateConnection() =>
        new SqliteConnection(_configuration.GetConnectionString("DefaultConnection"));

    public async Task<Placement?> GetByCodeAsync(string code)
    {
        using var connection = CreateConnection();
        var sql = "SELECT * FROM Placements WHERE Code = @Code;";
        return await connection.QueryFirstOrDefaultAsync<Placement>(sql, new { Code = code });
    }

    public async Task<IEnumerable<Campaign>> GetEligibleCampaignsAsync(string placementCode)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT c.* FROM Campaigns c
            INNER JOIN CampaignPlacements cp ON c.Id = cp.CampaignId
            INNER JOIN Placements p ON cp.PlacementId = p.Id
            WHERE p.Code = @PlacementCode AND c.Status = 'ACTIVE';";
        return await connection.QueryAsync<Campaign>(sql, new { PlacementCode = placementCode });
    }

    public async Task<long> CreateAsync(Placement placement)
    {
        using var connection = CreateConnection();
        var sql = @"
            INSERT INTO Placements (Code, Name, Description, CreatedAt)
            VALUES (@Code, @Name, @Description, @CreatedAt);
            SELECT last_insert_rowid();";
        return await connection.ExecuteScalarAsync<long>(sql, placement);
    }

    public async Task<IEnumerable<Placement>> GetAllAsync()
    {
        using var connection = CreateConnection();
        var sql = "SELECT * FROM Placements;";
        return await connection.QueryAsync<Placement>(sql);
    }
}
