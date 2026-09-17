using System;
using System.Globalization;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Caching.Memory;
using NSec.Cryptography;

namespace ADSOLUSOL.Presentation.Api.Security;

public enum VerificationState
{
    Unverified,
    Verified,
    NotConfigured
}

/// <summary>
/// Clase encargada de verificar criptográficamente las firmas de peticiones bajo el protocolo SOLUSOL_AUTH_V1.
/// </summary>
public class CoreSignatureVerifier
{
    private readonly IConfiguration _configuration;
    private readonly IMemoryCache _nonceCache;

    public CoreSignatureVerifier(IConfiguration configuration, IMemoryCache memoryCache)
    {
        _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
        _nonceCache = memoryCache ?? throw new ArgumentNullException(nameof(memoryCache));
    }

    /// <summary>
    /// Verifica una firma de acuerdo al protocolo SOLUSOL_AUTH_V1 (Ed25519).
    /// </summary>
    /// <param name="nodeId">Identificador del nodo que origina la petición.</param>
    /// <param name="timestamp">Timestamp ISO 8601 (UTC) de la petición.</param>
    /// <param name="nonce">Valor único para prevenir ataques de repetición.</param>
    /// <param name="context">El cuerpo de la petición (payload) que fue firmado.</param>
    /// <param name="signatureHeader">La firma Ed25519 en formato Base64.</param>
    /// <returns>Estado de la verificación.</returns>
    public VerificationState VerifySignature(string nodeId, string timestamp, string nonce, string context, string signatureHeader)
    {
        // 1. Validar presencia de parámetros de entrada
        if (string.IsNullOrWhiteSpace(nodeId) ||
            string.IsNullOrWhiteSpace(timestamp) ||
            string.IsNullOrWhiteSpace(nonce) ||
            context is null || // El body puede ser un string vacío ""
            string.IsNullOrWhiteSpace(signatureHeader))
        {
            return VerificationState.Unverified;
        }

        // 1a. Validar frescura del timestamp para prevenir ataques de replay.
        if (!DateTime.TryParse(timestamp, null, DateTimeStyles.RoundtripKind, out var requestTime))
        {
            return VerificationState.Unverified; // Formato de timestamp inválido.
        }
        if (Math.Abs((DateTime.UtcNow - requestTime).TotalSeconds) > 300) // Ventana de 5 minutos
        {
            return VerificationState.Unverified; // Timestamp expirado.
        }

        // 1b. Validar que el nonce no haya sido usado previamente.
        if (_nonceCache.TryGetValue(nonce, out _))
            return VerificationState.Unverified; // Replay detectado.

        // 2. Obtener la clave pública desde la configuración del sistema
        var publicKeyHex = _configuration[$"SolusolAuthV1:PublicKeys:{nodeId}"];
        if (string.IsNullOrEmpty(publicKeyHex))
        {
            // Si no hay clave para este NodeID, no está configurado.
            return VerificationState.NotConfigured;
        }

        try
        {
            // Marcar el nonce como usado para prevenir su reutilización.
            _nonceCache.Set(nonce, true, TimeSpan.FromMinutes(5));

            // 3. Reconstruir el mensaje canónico que fue firmado
            var canonicalMessage = $"SOLUSOL_AUTH_V1|{nodeId}|{timestamp}|{nonce}|{context}";
            byte[] messageBytes = Encoding.UTF8.GetBytes(canonicalMessage);

            // 4. Preparar clave y firma
            byte[] signatureBytes = Convert.FromBase64String(signatureHeader);
            byte[] publicKeyBytes = Convert.FromHexString(publicKeyHex);

            // 5. Verificar la firma usando Ed25519
            var algorithm = SignatureAlgorithm.Ed25519;
            var publicKey = PublicKey.Import(algorithm, publicKeyBytes, KeyBlobFormat.RawPublicKey);
            bool isValid = algorithm.Verify(publicKey, messageBytes, signatureBytes);

            return isValid ? VerificationState.Verified : VerificationState.Unverified;
        }
        catch (Exception) // FormatException, etc.
        {
            // Fail-Closed: Ante cualquier error de formato, clave o corrupción, se marca como No Verificado
            return VerificationState.Unverified;
        }
    }
}