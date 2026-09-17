using System;
using System.Text;
using System.Collections.Concurrent;
using ADSOLUSOL.Domain.Interfaces;
using NSec.Cryptography; // Librería requerida para Ed25519
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Http;

namespace ADSOLUSOL.Infrastructure.Security;

/// <summary>
/// Implementación del verificador de firmas Ed25519 para el contrato SOLUSOL_AUTH_V1.
/// </summary>
public class CoreSignatureVerifier : ICoreSignatureVerifier
{
    // En una aplicación real, las llaves públicas se obtendrían de una fuente confiable (ej. base de datos) basada en el NodeId.
    private readonly ConcurrentDictionary<string, DateTime> _nonceCache;
    private readonly IConfiguration _configuration;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private const int MaxTimestampSkewSeconds = 5;
    private const int NonceLifetimeMinutes = 5;

    public CoreSignatureVerifier(ConcurrentDictionary<string, DateTime> nonceCache, IConfiguration configuration, IHttpContextAccessor httpContextAccessor)
    {
        _nonceCache = nonceCache;
        _configuration = configuration;
        _httpContextAccessor = httpContextAccessor;
    }

    public bool Verify(string signature, string nodeId, long timestamp, string nonce, byte[] requestBody)
    {
        var httpContext = _httpContextAccessor.HttpContext ?? throw new InvalidOperationException("HttpContext is not available.");
        var request = httpContext.Request;

        // 1. Verificar la frescura del timestamp para prevenir ataques de repetición.
        var requestTime = DateTimeOffset.FromUnixTimeSeconds(timestamp);
        if (Math.Abs((DateTimeOffset.UtcNow - requestTime).TotalSeconds) > MaxTimestampSkewSeconds)
        {
            return false; // Timestamp inválido.
        }

        // 2. Reconstruir el payload canónico para la firma según SOLUSOL_AUTH_V1
        var versionBytes = Encoding.UTF8.GetBytes("SOLUSOL_AUTH_V1");
        var methodBytes = Encoding.UTF8.GetBytes(request.Method.ToUpperInvariant());
        var pathBytes = Encoding.UTF8.GetBytes(request.Path.ToString());
        var queryBytes = Encoding.UTF8.GetBytes(request.QueryString.ToString());
        var nodeIdBytes = Encoding.UTF8.GetBytes(nodeId);
        var timestampBytes = BitConverter.GetBytes(timestamp);
        var nonceBytes = Encoding.UTF8.GetBytes(nonce);
        // context is deprecated in favor of full request signing

        using var payloadStream = new MemoryStream();
        payloadStream.Write(versionBytes, 0, versionBytes.Length);
        payloadStream.Write(methodBytes, 0, methodBytes.Length);
        payloadStream.Write(pathBytes, 0, pathBytes.Length);
        payloadStream.Write(queryBytes, 0, queryBytes.Length);
        payloadStream.Write(nodeIdBytes, 0, nodeIdBytes.Length);
        payloadStream.Write(timestampBytes, 0, timestampBytes.Length);
        payloadStream.Write(nonceBytes, 0, nonceBytes.Length);
        payloadStream.Write(requestBody, 0, requestBody.Length);
        var payload = payloadStream.ToArray();

        // 3. Obtener la clave pública del nodo y verificar la firma
        var publicKeyHex = _configuration[$"SolusolAuthV1:PublicKeys:{nodeId}"];
        if (string.IsNullOrEmpty(publicKeyHex))
        {
            return false; // Nodo desconocido, no se puede verificar.
        }

        var publicKeyBytes = Convert.FromHexString(publicKeyHex);
        var publicKey = PublicKey.Import(SignatureAlgorithm.Ed25519, publicKeyBytes, KeyBlobFormat.RawPublicKey);

        var signatureBytes = Convert.FromBase64String(signature);
        var isSignatureValid = SignatureAlgorithm.Ed25519.Verify(publicKey, payload, signatureBytes);

        if (!isSignatureValid)
        {
            return false;
        }

        // 4. Solo si la firma es válida, verificar y consumir el nonce para prevenir replay attacks.
        if (!_nonceCache.TryAdd(nonce, DateTime.UtcNow))
        {
            return false; // Replay attack detectado.
        }

        // Limpieza de nonces antiguos (simplificado). Un BackgroundService es mejor para producción.
        var cutoff = DateTime.UtcNow.AddMinutes(-NonceLifetimeMinutes);
        foreach (var entry in _nonceCache.Where(kvp => kvp.Value < cutoff).ToList())
        {
            _nonceCache.TryRemove(entry.Key, out _);
        }

        return true; // Firma válida y nonce consumido.
    }
}