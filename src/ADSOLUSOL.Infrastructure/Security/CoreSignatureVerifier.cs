using ADSOLUSOL.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using NSec.Cryptography;
using System.Collections.Concurrent;
using System.Text;

namespace ADSOLUSOL.Infrastructure.Security;

public class CoreSignatureVerifier : ICoreSignatureVerifier
{
    private readonly ConcurrentDictionary<string, DateTime> _nonceCache;
    private readonly IConfiguration _configuration;
    private const int MaxTimestampSkewSeconds = 5;
    private const int NonceLifetimeMinutes = 5;

    public CoreSignatureVerifier(ConcurrentDictionary<string, DateTime> nonceCache, IConfiguration configuration)
    {
        _nonceCache = nonceCache;
        _configuration = configuration;
    }

    public bool Verify(string signature, string nodeId, long timestamp, string nonce, byte[] requestBody, string httpMethod, string requestPath, string queryString)
    {
        var requestTime = DateTimeOffset.FromUnixTimeSeconds(timestamp);
        if (Math.Abs((DateTimeOffset.UtcNow - requestTime).TotalSeconds) > MaxTimestampSkewSeconds)
        {
            return false;
        }

        var versionBytes = Encoding.UTF8.GetBytes("SOLUSOL_AUTH_V1");
        var methodBytes = Encoding.UTF8.GetBytes(httpMethod.ToUpperInvariant());
        var pathBytes = Encoding.UTF8.GetBytes(requestPath);
        var queryBytes = Encoding.UTF8.GetBytes(queryString);
        var nodeIdBytes = Encoding.UTF8.GetBytes(nodeId);
        var timestampBytes = BitConverter.GetBytes(timestamp);
        var nonceBytes = Encoding.UTF8.GetBytes(nonce);

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

        var publicKeyHex = _configuration[$"SolusolAuthV1:PublicKeys:{nodeId}"];
        if (string.IsNullOrEmpty(publicKeyHex))
        {
            return false;
        }

        byte[] publicKeyBytes;
        byte[] signatureBytes;
        try
        {
            publicKeyBytes = Convert.FromHexString(publicKeyHex);
            signatureBytes = Convert.FromBase64String(signature);
        }
        catch
        {
            return false;
        }

        var publicKey = PublicKey.Import(SignatureAlgorithm.Ed25519, publicKeyBytes, KeyBlobFormat.RawPublicKey);
        var isSignatureValid = SignatureAlgorithm.Ed25519.Verify(publicKey, payload, signatureBytes);

        if (!isSignatureValid)
        {
            return false;
        }

        if (!_nonceCache.TryAdd(nonce, DateTime.UtcNow))
        {
            return false;
        }

        var cutoff = DateTime.UtcNow.AddMinutes(-NonceLifetimeMinutes);
        foreach (var entry in _nonceCache.Where(kvp => kvp.Value < cutoff).ToList())
        {
            _nonceCache.TryRemove(entry.Key, out _);
        }

        return true;
    }
}
