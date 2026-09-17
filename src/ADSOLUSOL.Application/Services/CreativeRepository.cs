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

    public async Task<long> CreateAsync(Creative creative)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = @"
            INSERT INTO Creatives (Name, ContentUrl, TargetUrl, IsEnabled, CreatedAt, UpdatedAt)
            VALUES (@Name, @ContentUrl, @TargetUrl, @IsEnabled, @CreatedAt, @UpdatedAt);
            SELECT last_insert_rowid();";
        return await connection.ExecuteScalarAsync<long>(sql, creative);
    }

    public async Task<Creative?> GetByIdAsync(long creativeId)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = "SELECT * FROM Creatives WHERE Id = @CreativeId;";
        return await connection.QuerySingleOrDefaultAsync<Creative>(sql, new { CreativeId = creativeId });
    }

    public async Task<Creative?> GetEligibleCreativeForCampaignAsync(string campaignId)
    {
        await using var connection = new SqliteConnection(_connectionString);
        // This assumes a simple selection logic. A real-world scenario would be more complex.
        const string sql = "SELECT cr.* FROM Creatives cr JOIN CampaignCreatives cc ON cr.Id = cc.CreativeId WHERE cc.CampaignId = @CampaignId AND cr.IsEnabled = 1 LIMIT 1;";
        return await connection.QuerySingleOrDefaultAsync<Creative>(sql, new { CampaignId = campaignId });
    }
}