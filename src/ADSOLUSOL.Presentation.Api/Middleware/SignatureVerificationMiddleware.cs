﻿﻿﻿using System.Security.Cryptography;
using System.Text;
using ADSOLUSOL.Domain.Interfaces;
using NSec.Cryptography;
using Microsoft.Extensions.Caching.Memory;

namespace ADSOLUSOL.Presentation.Api.Middleware;

public class SignatureVerificationMiddleware
{
    private readonly RequestDelegate _next;
    private static readonly PathString[] s_publicPaths = { "/", "/api/health" };

    public SignatureVerificationMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, INodeRegistry nodeRegistry, IMemoryCache nonceCache)
    {
        // FIX: Bypass signature verification for public UI and health check endpoints.
        if (Array.Exists(s_publicPaths, p => context.Request.Path.StartsWithSegments(p)) && context.Request.Path.Value?.EndsWith("blazor.web.js") != true)
        {
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

        // FIX: Implement nonce replay protection.
        if (nonceCache.TryGetValue(nonce.ToString(), out _))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Replay attack detected (nonce already used).");
            return;
        }
        nonceCache.Set(nonce.ToString(), true, TimeSpan.FromMinutes(5));

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

        string bodyHash = string.IsNullOrEmpty(body) ? "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" : Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(body))).ToLower();

        string canonicalString = $"{timestamp}|{nonce}|{context.Request.Method.ToUpper()}|{context.Request.Path.Value}|{context.Request.QueryString.Value}|{bodyHash}";

        if (!VerifySignature(publicKeyHex, canonicalString, signature.ToString()))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            await context.Response.WriteAsync("Invalid signature.");
            return;
        }

        // Authentication and Authorization successful. Set TenantId for downstream controllers.
        context.Items["TenantId"] = tenantId;

        await _next(context);
    }

    private bool IsTimestampInvalid(long timestamp)
    {
        var requestTime = DateTimeOffset.FromUnixTimeSeconds(timestamp);
        var now = DateTimeOffset.UtcNow;
        // Reject requests older than 5 minutes or more than 1 minute in the future.
        return requestTime < now.AddMinutes(-5) || requestTime > now.AddMinutes(1);
    }

    private bool VerifySignature(string publicKeyHex, string message, string signatureBase64)
    {
        try
        {
            byte[] publicKeyBytes = Convert.FromHexString(publicKeyHex);
            byte[] dataToVerify = Encoding.UTF8.GetBytes(message);
            byte[] signatureBytes = Convert.FromBase64String(signatureBase64);

            var algorithm = SignatureAlgorithm.Ed25519;
            var pubKey = PublicKey.Import(algorithm, publicKeyBytes, KeyBlobFormat.RawPublicKey);
            
            return algorithm.Verify(pubKey, dataToVerify, signatureBytes);
        }
        catch
        {
            return false;
        }
    }
}