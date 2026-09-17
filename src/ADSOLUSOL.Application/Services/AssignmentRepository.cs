using ADSOLUSOL.Domain.Repositories;
using Dapper;
using Microsoft.Data.Sqlite;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AssignmentRepository : IAssignmentRepository
{
    private readonly string _connectionString;

    public AssignmentRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task AssignCreativeToCampaignAsync(string campaignId, long creativeId)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = "INSERT INTO CampaignCreatives (CampaignId, CreativeId) VALUES (@CampaignId, @CreativeId);";
        await connection.ExecuteAsync(sql, new { CampaignId = campaignId, CreativeId = creativeId });
    }

    public async Task AssignPlacementToCampaignAsync(string campaignId, long placementId)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = "INSERT INTO CampaignPlacements (CampaignId, PlacementId) VALUES (@CampaignId, @PlacementId);";
        await connection.ExecuteAsync(sql, new { CampaignId = campaignId, PlacementId = placementId });
    }
}