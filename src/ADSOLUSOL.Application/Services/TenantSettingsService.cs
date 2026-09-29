using System.Collections.Concurrent;
using ADSOLUSOL.Application.DTOs;
using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Application.Services;

public class TenantSettingsService : ITenantSettingsService
{
    private readonly ITenantSettingsRepository _repository;
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
    private static readonly ConcurrentDictionary<string, (TenantSettingsDto Dto, DateTime ExpiresAtUtc)> _cache = new();

    public TenantSettingsService(ITenantSettingsRepository repository)
    {
        _repository = repository;
    }

    private static string GetCacheKey(string tenantId) => $"tenant_settings_{tenantId}";

    public async Task<TenantSettingsDto> GetSettingsAsync(string tenantId)
    {
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            throw new ArgumentException("TenantId es requerido.", nameof(tenantId));
        }

        var cacheKey = GetCacheKey(tenantId);
        if (_cache.TryGetValue(cacheKey, out var cached) && cached.ExpiresAtUtc > DateTime.UtcNow)
        {
            return cached.Dto;
        }

        var entities = (await _repository.GetAllByTenantAsync(tenantId)).ToList();
        var dto = new TenantSettingsDto
        {
            TenantId = tenantId,
            Settings = entities.ToDictionary(e => e.Key, e => e.Value, StringComparer.OrdinalIgnoreCase),
            LastUpdatedAtUtc = entities.Count > 0 ? entities.Max(e => e.UpdatedAtUtc) : DateTime.UtcNow
        };

        _cache[cacheKey] = (dto, DateTime.UtcNow.Add(CacheTtl));
        return dto;
    }

    public async Task<string?> GetSettingValueAsync(string tenantId, string key, string? defaultValue = null)
    {
        var settingsDto = await GetSettingsAsync(tenantId);
        return settingsDto.Settings.TryGetValue(key, out var val) ? val : defaultValue;
    }

    public async Task<TenantSettingsDto> UpdateSettingsAsync(string tenantId, UpdateTenantSettingsDto updateDto)
    {
        if (string.IsNullOrWhiteSpace(tenantId))
        {
            throw new ArgumentException("TenantId es requerido.", nameof(tenantId));
        }

        await _repository.UpsertBatchAsync(tenantId, updateDto.Settings);
        _cache.TryRemove(GetCacheKey(tenantId), out _);
        return await GetSettingsAsync(tenantId);
    }
}