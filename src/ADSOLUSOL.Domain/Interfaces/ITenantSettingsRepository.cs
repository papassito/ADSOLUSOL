using ADSOLUSOL.Domain.Entities;

namespace ADSOLUSOL.Domain.Interfaces;

public interface ITenantSettingsRepository
{
    Task<IEnumerable<TenantSetting>> GetAllByTenantAsync(string tenantId);
    Task<TenantSetting?> GetByKeyAsync(string tenantId, string key);
    Task UpsertAsync(TenantSetting setting);
    Task UpsertBatchAsync(string tenantId, IDictionary<string, string> settings);
}