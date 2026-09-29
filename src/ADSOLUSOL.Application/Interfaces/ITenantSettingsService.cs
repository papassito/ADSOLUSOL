using ADSOLUSOL.Application.DTOs;

namespace ADSOLUSOL.Application.Interfaces;

public interface ITenantSettingsService
{
    Task<TenantSettingsDto> GetSettingsAsync(string tenantId);
    Task<string?> GetSettingValueAsync(string tenantId, string key, string? defaultValue = null);
    Task<TenantSettingsDto> UpdateSettingsAsync(string tenantId, UpdateTenantSettingsDto updateDto);
}