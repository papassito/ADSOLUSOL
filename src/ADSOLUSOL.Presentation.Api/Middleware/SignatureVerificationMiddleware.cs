using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Http;
using System.IO;
using System.Text;

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
        var request = context.Request;

        if (!request.Headers.TryGetValue("X-Solusol-Signature", out var signature) ||
            !request.Headers.TryGetValue("X-Solusol-Node-Id", out var nodeId) ||
            !request.Headers.TryGetValue("X-Solusol-Timestamp", out var timestampStr) ||
            !request.Headers.TryGetValue("X-Solusol-Nonce", out var nonce) ||
            !long.TryParse(timestampStr, out var timestamp))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Missing or invalid authentication headers.");
            return;
        }

        request.EnableBuffering();
        using var reader = new StreamReader(request.Body, Encoding.UTF8, leaveOpen: true);
        var body = await reader.ReadToEndAsync();
        request.Body.Position = 0;

        var bodyBytes = Encoding.UTF8.GetBytes(body);
        var isValid = verifier.Verify(
            signature!, nodeId!, timestamp, nonce!, bodyBytes,
            request.Method, request.Path.ToString(), request.QueryString.ToString()
        );

        if (!isValid)
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            await context.Response.WriteAsync("Invalid signature.");
            return;
        }

        await _next(context);
    }
}
