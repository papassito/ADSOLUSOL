using System.Threading.Tasks;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Http;

namespace ADSOLUSOL.Presentation.Api.Middleware;

public class SignatureVerificationMiddleware
{
    private readonly RequestDelegate _next;

    public SignatureVerificationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ICoreSignatureVerifier verifier)
    {
        // Extraer los headers de autenticaciÃ³n de SOLUSOL
        context.Request.Headers.TryGetValue("X-Solusol-Signature", out var signature);
        context.Request.Headers.TryGetValue("X-Solusol-Node-Id", out var nodeId);
        context.Request.Headers.TryGetValue("X-Solusol-Timestamp", out var timestampStr);
        context.Request.Headers.TryGetValue("X-Solusol-Nonce", out var nonce);
        context.Request.Headers.TryGetValue("TenantId", out var tenantId); // Capturar tambiÃ©n el TenantId

        if (string.IsNullOrEmpty(signature) || string.IsNullOrEmpty(nodeId) || !long.TryParse(timestampStr, out var timestamp) || string.IsNullOrEmpty(nonce))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Missing required SOLUSOL authentication headers.");
            return;
        }

        // Leer el cuerpo de la peticiÃ³n de forma segura
        context.Request.EnableBuffering();
        var body = await new System.IO.StreamReader(context.Request.Body).ReadToEndAsync();
        var bodyBytes = System.Text.Encoding.UTF8.GetBytes(body);
        context.Request.Body.Position = 0; // Rebobinar el stream para el siguiente middleware/controlador

        if (!verifier.Verify(signature!, nodeId!, timestamp, nonce!, bodyBytes))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            await context.Response.WriteAsync("Invalid signature.");
            return;
        }

        // Si la verificaciÃ³n es exitosa, propagar el TenantId a travÃ©s del contexto de la peticiÃ³n
        if (!string.IsNullOrEmpty(tenantId))
        {
            context.Items["TenantId"] = tenantId.ToString();
        }

        await _next(context);
    }
}
