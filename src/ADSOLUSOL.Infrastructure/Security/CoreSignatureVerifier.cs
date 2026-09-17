using System;
using System.Text;
using System.Collections.Concurrent;
using ADSOLUSOL.Domain.Interfaces;
using NSec.Cryptography; // Librería requerida para Ed25519

namespace ADSOLUSOL.Infrastructure.Security;

/// <summary>
/// Implementación del verificador de firmas Ed25519 para el contrato SOLUSOL_AUTH_V1.
/// </summary>
public class CoreSignatureVerifier : ICoreSignatureVerifier
{
    // En una aplicación real, las llaves públicas se obtendrían de una fuente confiable (ej. base de datos) basada en el NodeId.
    private readonly PublicKey _publicKey;
    private readonly ConcurrentDictionary<string, DateTime> _nonceCache;
    private const int MaxTimestampSkewSeconds = 5;
    private const int NonceLifetimeMinutes = 5;

    public CoreSignatureVerifier(ConcurrentDictionary<string, DateTime> nonceCache)
    {
        // ESTA ES UNA LLAVE PÚBLICA DE EJEMPLO. Debe ser reemplazada por un sistema de gestión de llaves real.
        _nonceCache = nonceCache;
        var publicKeyBytes = Convert.FromBase64String("MCowBQYDK2VwAyEAlU7j+nK5b+sWWxV+A/3j/Kj/h/yF+c8G+A/D3A/yF+c=");
        _publicKey = PublicKey.Import(SignatureAlgorithm.Ed25519, publicKeyBytes, KeyBlobFormat.PkixPublicKey);
    }

    public bool Verify(string signature, string nodeId, long timestamp, string nonce, byte[] requestBody)
    {
        // 1. Verificar la frescura del timestamp para prevenir ataques de repetición.
        var requestTime = DateTimeOffset.FromUnixTimeSeconds(timestamp);
        if (Math.Abs((DateTimeOffset.UtcNow - requestTime).TotalSeconds) > MaxTimestampSkewSeconds)
        {
            return false; // Timestamp inválido.
        }

        // 2. Verificar que el 'nonce' no haya sido usado previamente.
        if (!_nonceCache.TryAdd(nonce, DateTime.UtcNow))
        {
            return false; // Nonce ya existe, posible ataque de replay.
        }

        // Limpieza periódica de nonces antiguos (simplificado para este ejemplo)
        // En una app real, esto se haría en un background service.
        // Esta implementación es básica y puede no ser eficiente a gran escala.
        foreach (var entry in _nonceCache)
        {
            if ((DateTime.UtcNow - entry.Value).TotalMinutes > NonceLifetimeMinutes)
            {
                _nonceCache.TryRemove(entry.Key, out _);
            }
        }

        // 3. Reconstruir el payload canónico para SOLUSOL_AUTH_V1 (concatenación de bytes).
        var versionBytes = Encoding.UTF8.GetBytes("SOLUSOL_AUTH_V1");
        var timestampBytes = BitConverter.GetBytes(timestamp);
        var nonceBytes = Encoding.UTF8.GetBytes(nonce);
        var nodeIdBytes = Encoding.UTF8.GetBytes(nodeId);

        var payloadStream = new System.IO.MemoryStream();
        payloadStream.Write(versionBytes, 0, versionBytes.Length);
        payloadStream.Write(timestampBytes, 0, timestampBytes.Length);
        payloadStream.Write(nonceBytes, 0, nonceBytes.Length);
        payloadStream.Write(nodeIdBytes, 0, nodeIdBytes.Length);
        payloadStream.Write(requestBody, 0, requestBody.Length);
        var payload = payloadStream.ToArray();

        // 4. Realizar la verificación criptográfica con Ed25519.
        var signatureBytes = Convert.FromBase64String(signature);
        return SignatureAlgorithm.Ed25519.Verify(_publicKey, payload, signatureBytes);
    }
}