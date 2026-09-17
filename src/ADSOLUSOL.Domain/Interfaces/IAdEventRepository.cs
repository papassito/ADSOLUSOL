using System.Data;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IAdEventRepository
{
    // Se usa la abstracción IDbTransaction en lugar de un tipo concreto de SQLite
    Task LogEventAsync(string eventType, Guid campaignId, IDbTransaction transaction);
}