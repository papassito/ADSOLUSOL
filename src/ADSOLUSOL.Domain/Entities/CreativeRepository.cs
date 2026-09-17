using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Repositories;
using Dapper;
using Microsoft.Data.Sqlite;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class CreativeRepository : ICreativeRepository
{
    private readonly string _connectionString;

    public CreativeRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<Creative?> GetEligibleCreativeForCampaign(long campaignId)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = "SELECT cr.* FROM Creatives cr JOIN CampaignCreatives cc ON cr.Id = cc.CreativeId WHERE cc.CampaignId = @CampaignId AND cr.IsEnabled = 1 LIMIT 1;";
        return await connection.QuerySingleOrDefaultAsync<Creative>(sql, new { CampaignId = campaignId });
    }
}