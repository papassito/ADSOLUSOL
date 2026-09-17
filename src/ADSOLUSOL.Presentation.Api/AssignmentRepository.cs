using ADSOLUSOL.Domain.Interfaces;
using Dapper;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AssignmentRepository : IAssignmentRepository
{
    private readonly IConfiguration _configuration;

    public AssignmentRepository(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    private IDbConnection CreateConnection()
    {
        return new SqliteConnection(_configuration.GetConnectionString("DefaultConnection"));
    }

    public async Task AssignCreativeToCampaignAsync(string campaignId, long creativeId)
    {
        using var connection = CreateConnection();
        var sql = "INSERT INTO CampaignCreatives (CampaignId, CreativeId) VALUES (@CampaignId, @CreativeId) ON CONFLICT(CampaignId, CreativeId) DO NOTHING;";
        await connection.ExecuteAsync(sql, new { CampaignId = campaignId, CreativeId = creativeId });
    }

    public async Task AssignPlacementToCampaignAsync(string campaignId, long placementId)
    {
        using var connection = CreateConnection();
        var sql = "INSERT INTO CampaignPlacements (CampaignId, PlacementId) VALUES (@CampaignId, @PlacementId) ON CONFLICT(CampaignId, PlacementId) DO NOTHING;";
        await connection.ExecuteAsync(sql, new { CampaignId = campaignId, PlacementId = placementId });
    }
}