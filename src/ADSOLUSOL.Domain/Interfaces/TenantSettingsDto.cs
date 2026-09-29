namespace ADSOLUSOL.Application.DTOs;

public class TenantSettingsDto
{
    public string TenantId { get; set; } = string.Empty;
    public Dictionary<string, string> Settings { get; set; } = new(StringComparer.OrdinalIgnoreCase);
    public DateTime LastUpdatedAtUtc { get; set; }
}

public class UpdateTenantSettingsDto
{
    public Dictionary<string, string> Settings { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}