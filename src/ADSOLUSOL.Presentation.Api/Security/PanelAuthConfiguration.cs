namespace ADSOLUSOL.Presentation.Api.Security;

public static class PanelAuthConfiguration
{
    public static string? GetPasswordHash(IConfiguration configuration, string tenantId) =>
        configuration[$"PanelAuth:Tenants:{tenantId}"] ??
        configuration[$"PanelAuth:Tenants:{tenantId.Replace('-', '_')}"];
}
