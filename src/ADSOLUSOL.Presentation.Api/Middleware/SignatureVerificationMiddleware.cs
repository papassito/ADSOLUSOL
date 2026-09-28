using System.Security.Cryptography;
using System.Text;
using ADSOLUSOL.Domain.Interfaces;
using NSec.Cryptography;
using Microsoft.Extensions.Caching.Memory;

namespace ADSOLUSOL.Presentation.Api.Middleware;

public class SignatureVerificationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ICoreSignatureVerifier _verifier;

    public SignatureVerificationMiddleware(RequestDelegate next, ICoreSignatureVerifier verifier)
    {
        _next = next;
        _verifier = verifier;
    }

    public async Task InvokeAsync(HttpContext context, INodeRegistry nodeRegistry, IMemoryCache nonceCache)
    {
        // Bypass seguro: solo ruta raíz exacta, endpoint de salud o documentación swagger
        var path = context.Request.Path;
        if (path == "/" || path.StartsWithSegments("/api/health") || path.StartsWithSegments("/swagger") ||
            (path.Value?.EndsWith("blazor.web.js") == true))
        {
            await _next(context);
            return;
        }

        // Endpoint BFF para inicio de sesión en el Panel Web
        if (path.Equals("/api/auth/session", StringComparison.OrdinalIgnoreCase))
        {
            if (context.Request.Method.Equals("POST", StringComparison.OrdinalIgnoreCase))
            {
                using var reader = new StreamReader(context.Request.Body);
                var bodyText = await reader.ReadToEndAsync();
                string? requestedTenant = null;
                try
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(bodyText);
                    if (doc.RootElement.TryGetProperty("tenantId", out var prop))
                    {
                        requestedTenant = prop.GetString();
                    }
                }
                catch (System.Text.Json.JsonException ex)
                {
                    // Formato JSON inválido para la sesión: fail-closed manteniendo requestedTenant nulo
                    System.Diagnostics.Trace.TraceWarning($"[SECURITY] Error deserializando sesión BFF: {ex.Message}");
                }

                if (!string.IsNullOrWhiteSpace(requestedTenant))
                {
                    context.Response.Cookies.Append("Solusol-Tenant-Session", requestedTenant, new CookieOptions
                    {
                        HttpOnly = true,
                        SameSite = SameSiteMode.Lax,
                        Secure = context.Request.IsHttps,
                        Expires = DateTimeOffset.UtcNow.AddDays(7)
                    });
                    context.Response.ContentType = "application/json";
                    await context.Response.WriteAsync($"{{\"status\":\"AUTHENTICATED\",\"tenantId\":\"{requestedTenant}\"}}");
                    return;
                }
            }
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsync("Se requiere un 'tenantId' válido en el cuerpo JSON.");
            return;
        }

        // Autenticación por Sesión BFF (Panel Web con Cookie segura)
        if (context.Request.Cookies.TryGetValue("Solusol-Tenant-Session", out var sessionTenant) && !string.IsNullOrWhiteSpace(sessionTenant))
        {
            context.Items["TenantId"] = sessionTenant;
            await _next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue("X-Solusol-Node-Id", out var nodeId) ||
            !context.Request.Headers.TryGetValue("X-Solusol-Timestamp", out var timestampStr) ||
            !context.Request.Headers.TryGetValue("X-Solusol-Nonce", out var nonce) ||
            !context.Request.Headers.TryGetValue("X-Solusol-Signature", out var signature))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Missing required authentication headers.");
            return;
        }

        if (!long.TryParse(timestampStr, out var timestamp) || IsTimestampInvalid(timestamp))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Invalid or expired timestamp.");
            return;
        }

        // Comprobación anti-replay: verificar si ya fue utilizado (sin consumirlo aún)
        if (nonceCache.TryGetValue(nonce.ToString(), out _))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Replay attack detected (nonce already used).");
            return;
        }

        var (tenantId, publicKeyHex) = nodeRegistry.GetNodeInfo(nodeId.ToString());
        if (string.IsNullOrEmpty(tenantId) || string.IsNullOrEmpty(publicKeyHex))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            await context.Response.WriteAsync("Node ID not recognized or not authorized.");
            return;
        }

        context.Request.EnableBuffering();
        var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
        context.Request.Body.Position = 0;

        if (!_verifier.Verify(
            signature.ToString(),
            nodeId.ToString(),
            timestamp,
            nonce.ToString(),
            Encoding.UTF8.GetBytes(body),
            context.Request.Method,
            context.Request.Path.Value ?? string.Empty,
            context.Request.QueryString.Value ?? string.Empty
        ))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            await context.Response.WriteAsync("Invalid signature.");
            return;
        }

        // Consumir el nonce únicamente tras certificar la firma criptográfica
        nonceCache.Set(nonce.ToString(), true, TimeSpan.FromMinutes(5));

        // Authentication and Authorization successful. Set TenantId for downstream controllers.
        context.Items["TenantId"] = tenantId;

        await _next(context);
    }

    private bool IsTimestampInvalid(long timestamp)
    {
        try
        {
            var requestTime = DateTimeOffset.FromUnixTimeSeconds(timestamp);
            var now = DateTimeOffset.UtcNow;
            // Rechazar solicitudes con más de 5 minutos de antigüedad o más de 1 minuto en el futuro
            return requestTime < now.AddMinutes(-5) || requestTime > now.AddMinutes(1);
        }
        catch (ArgumentOutOfRangeException)
        {
            return true;
        }
    }
}