using ADSOLUSOL.Domain.Entities;
using Dapper;
using Microsoft.Data.Sqlite;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AdEventRepository : IAdEventRepository
{
    private readonly string _connectionString;

    public AdEventRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<bool> ExistsAsync(string eventId)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = "SELECT 1 FROM AdEvents WHERE EventId = @EventId;";
        return await connection.ExecuteScalarAsync<bool>(sql, new { EventId = eventId });
    }

    public async Task AddAsync(AdEvent adEvent, SqliteTransaction transaction)
    {
        const string sql = @"
            INSERT INTO AdEvents (EventId, EventType, CampaignId, CreativeId, PlacementCode, OccurredAt, ReceivedAt)
            VALUES (@EventId, @EventType, @CampaignId, @CreativeId, @PlacementCode, @OccurredAt, @ReceivedAt);";
        
        await transaction.Connection.ExecuteAsync(sql, adEvent, transaction);
    }

    public async Task<int> CountByTypeAsync(string campaignId, string eventType)
    {
        await using var connection = new SqliteConnection(_connectionString);
        const string sql = @"
            SELECT COUNT(*) FROM AdEvents
            WHERE CampaignId = @CampaignId AND EventType = @EventType;";
        
        return await connection.ExecuteScalarAsync<int>(sql, new { CampaignId = campaignId, EventType = eventType });
    }
}