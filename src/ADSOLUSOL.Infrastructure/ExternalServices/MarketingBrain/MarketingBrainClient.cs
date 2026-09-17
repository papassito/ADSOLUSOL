using System;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using NSec.Cryptography;
using ADSOLUSOL.Domain.ValueObjects;
using System.Threading;

namespace ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;

/// <summary>
/// Client to interact with the SOLUSOL Center Intelligence (SIC) for marketing telemetry.
/// Implements the SOLUSOL_AUTH_V1 protocol for secure communication.
/// </summary>
public class MarketingBrainClient : IMarketingBrainService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<MarketingBrainClient> _logger;
    private readonly string _selfNodeId;
    private const string TenantId = "solusol-internal";

    public MarketingBrainClient(HttpClient httpClient, IConfiguration configuration, ILogger<MarketingBrainClient> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
        // Read this node's identity from configuration
        _selfNodeId = _configuration["SolusolAuthV1:SelfNodeId"] ?? "ADS_NODE_01";
    }

    /// <summary>
    /// Emits a telemetry signal to the SIC backend, signed with SOLUSOL_AUTH_V1.
    /// </summary>
    /// <param name="eventType">The type of the event being reported (e.g., "ADS_CLICK").</param>
    /// <param name="eventPayload">The data associated with the event.</param>
    public async Task EmitTelemetryAsync(string eventType, object eventPayload)
    {
        var privateKeyHex = _configuration["SolusolAuthV1:PrivateKey"];
        if (string.IsNullOrEmpty(privateKeyHex))
        {
            // Adhering to Zero-Synthetic: throw an exception if the service is misconfigured.
            throw new InvalidOperationException("Private key for this node ('SolusolAuthV1:PrivateKey') is not configured. Cannot emit telemetry.");
        }

        // 1. Preparar payload y elementos de autenticación
        var timestamp = new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds();

        var nonceBytes = new byte[16];
        RandomNumberGenerator.Fill(nonceBytes);
        var nonce = Convert.ToHexString(nonceBytes).ToLowerInvariant();

        var signals = new[] { new { source_id = _selfNodeId, type = eventType, payload = eventPayload, timestamp } };
        var signalsJson = JsonSerializer.Serialize(signals);
        var signalsJsonBytes = Encoding.UTF8.GetBytes(signalsJson);

        // 2. Construir el payload canónico para la firma según SOLUSOL_AUTH_V1
        // Es una concatenación directa de bytes: VERSION | TIMESTAMP | NONCE | NODE_ID | BODY
        var versionBytes = Encoding.UTF8.GetBytes("SOLUSOL_AUTH_V1");
        var timestampBytes = BitConverter.GetBytes(timestamp);
        var nonceUtf8Bytes = Encoding.UTF8.GetBytes(nonce);
        var nodeIdBytes = Encoding.UTF8.GetBytes(_selfNodeId);

        using var payloadStream = new MemoryStream();
        payloadStream.Write(versionBytes, 0, versionBytes.Length);
        payloadStream.Write(timestampBytes, 0, timestampBytes.Length);
        payloadStream.Write(nonceUtf8Bytes, 0, nonceUtf8Bytes.Length);
        payloadStream.Write(nodeIdBytes, 0, nodeIdBytes.Length);
        payloadStream.Write(signalsJsonBytes, 0, signalsJsonBytes.Length);
        var dataToSign = payloadStream.ToArray();

        // 3. Firmar el payload canónico con la clave privada Ed25519
        var fullKeyBytes = Convert.FromHexString(privateKeyHex);
        var algorithm = SignatureAlgorithm.Ed25519;
        using var key = Key.Import(algorithm, fullKeyBytes, KeyBlobFormat.RawPrivateKey);
        var signatureBytes = algorithm.Sign(key, dataToSign);
        var signatureBase64 = Convert.ToBase64String(signatureBytes);

        // 4. Crear y enviar la petición HTTP
        // El cuerpo es el payload de negocio (el JSON de las señales).
        // Los datos de autenticación se envían en las cabeceras.
        using var request = new HttpRequestMessage(HttpMethod.Post, "telemetry");
        request.Content = new StringContent(signalsJson, Encoding.UTF8, "application/json");

        // Añadir todas las cabeceras requeridas por el protocolo SOLUSOL_AUTH_V1
        request.Headers.Add("X-Solusol-Node-Id", _selfNodeId);
        request.Headers.Add("X-Solusol-Timestamp", timestamp.ToString());
        request.Headers.Add("X-Solusol-Nonce", nonce);
        request.Headers.Add("X-Solusol-Signature", signatureBase64);
        request.Headers.Add("TenantId", TenantId);

        using var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
    }

    /// <summary>
    /// Checks if the SIC service is available by sending a lightweight request.
    /// </summary>
    public async Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, "api/health"); // Correctly targets the health endpoint
            using var response = await _httpClient.SendAsync(request, cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            _logger.LogTrace(ex, "SIC health check failed. The service appears to be unavailable.");
            return false;
        }
    }

    public async Task<AdContent?> GenerateAdContentAsync(Campaign campaign, CancellationToken token = default)
    {
        // This method is not yet implemented according to the new contracts.
        // Throwing an exception ensures the caller handles the unavailability,
        // which the global middleware will catch and convert to a 503 response.
        await Task.CompletedTask; // To satisfy async signature
        throw new NotImplementedException("Ad content generation contract with SIC is not yet finalized.");
    }
}