using System.Data;
using ADSOLUSOL.Domain.Interfaces;
using Dapper; // Se asume el uso de Dapper para la persistencia

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AdEventRepository : IAdEventRepository
{
    // La implementación concreta utiliza la abstracción IDbTransaction.
    // La conexión se obtendría de una Unidad de Trabajo o un DbContext.
    public async Task LogEventAsync(string eventType, Guid campaignId, IDbTransaction transaction)
    {
        var sql = "INSERT INTO AdEvents (EventType, CampaignId, Timestamp) VALUES (@EventType, @CampaignId, @Timestamp);";
        await transaction.Connection.ExecuteAsync(sql, new { EventType = eventType, CampaignId = campaignId, Timestamp = DateTime.UtcNow }, transaction);
    }
}