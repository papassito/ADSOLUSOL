using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class TenantSettingsRepository : ITenantSettingsRepository
{
    private readonly AppDbContext _context;

    public TenantSettingsRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<TenantSetting>> GetAllByTenantAsync(string tenantId)
    {
        return await _context.Set<TenantSetting>()
            .AsNoTracking()
            .Where(s => s.TenantId == tenantId)
            .ToListAsync();
    }

    public async Task<TenantSetting?> GetByKeyAsync(string tenantId, string key)
    {
        return await _context.Set<TenantSetting>()
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.TenantId == tenantId && s.Key == key);
    }

    public async Task UpsertAsync(TenantSetting setting)
    {
        var existing = await _context.Set<TenantSetting>()
            .FirstOrDefaultAsync(s => s.TenantId == setting.TenantId && s.Key == setting.Key);

        if (existing == null)
        {
            setting.UpdatedAtUtc = DateTime.UtcNow;
            await _context.Set<TenantSetting>().AddAsync(setting);
        }
        else
        {
            existing.Value = setting.Value;
            existing.UpdatedAtUtc = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
    }

    public async Task UpsertBatchAsync(string tenantId, IDictionary<string, string> settings)
    {
        var existing = await _context.Set<TenantSetting>()
            .Where(s => s.TenantId == tenantId)
            .ToListAsync();

        var existingMap = existing.ToDictionary(e => e.Key, StringComparer.OrdinalIgnoreCase);
        var now = DateTime.UtcNow;

        foreach (var kvp in settings)
        {
            if (existingMap.TryGetValue(kvp.Key, out var current))
            {
                current.Value = kvp.Value;
                current.UpdatedAtUtc = now;
            }
            else
            {
                await _context.Set<TenantSetting>().AddAsync(new TenantSetting
                {
                    TenantId = tenantId,
                    Key = kvp.Key,
                    Value = kvp.Value,
                    UpdatedAtUtc = now
                });
            }
        }

        await _context.SaveChangesAsync();
    }
}