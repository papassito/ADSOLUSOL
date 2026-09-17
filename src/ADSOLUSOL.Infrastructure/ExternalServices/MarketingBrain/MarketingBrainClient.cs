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

        var fullKeyBytes = Convert.FromHexString(privateKeyHex);
        // The public key is the last 32 bytes of the 64-byte expanded private key.
        var publicKeyBytes = fullKeyBytes.AsSpan(32).ToArray(); 

        using var sha256 = SHA256.Create();
        var nodeId = Convert.ToHexString(sha256.ComputeHash(publicKeyBytes)).ToLowerInvariant();

        var timestamp = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.ffffffZ");
        
        var nonceBytes = new byte[16];
        RandomNumberGenerator.Fill(nonceBytes);
        var nonce = Convert.ToHexString(nonceBytes).ToLowerInvariant();

        var signals = new[] { new { source_id = nodeId, type = eventType, payload = eventPayload, timestamp = new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds() } };

        // The signature covers the exact JSON representation of the signals array.
        var signalsJson = JsonSerializer.Serialize(signals);
        var canonicalStringToSign = $"{timestamp}|{nonce}|{nodeId}|{signalsJson}";
        var dataToSign = Encoding.UTF8.GetBytes(canonicalStringToSign);
        var algorithm = SignatureAlgorithm.Ed25519;
        using var key = Key.Import(algorithm, fullKeyBytes, KeyBlobFormat.RawPrivateKey);
        var signatureBytes = algorithm.Sign(key, dataToSign);
        var signatureBase64 = Convert.ToBase64String(signatureBytes);


        var telemetryPayload = new
        {
            authentication = new {
                node_id = nodeId,
                timestamp,
                nonce,
                signature = signatureBase64,
                context = new {}
            },
            version = "sic.telemetry.v1",
            actor_id = nodeId,
            tenant_id = TenantId,
            capability = "telemetry:submit",
            resource = "sic:collector",
            signals = signals
        };

        var payloadJson = JsonSerializer.Serialize(telemetryPayload);
        using var request = new HttpRequestMessage(HttpMethod.Post, "telemetry");
        request.Content = new StringContent(payloadJson, Encoding.UTF8, "application/json");

        request.Headers.Add("X-Solusol-Node-Id", nodeId);
        request.Headers.Add("X-Solusol-Signature", signatureBase64);

        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode(); // Throws HttpRequestException on non-2xx responses.
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