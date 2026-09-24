using ADSOLUSOL.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using System.Net.Http;
using System.Net.Http.Json;

namespace ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;

public class MarketingBrainClient : IMarketingBrainService
{
    private readonly HttpClient _httpClient;

    public MarketingBrainClient(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        if (_httpClient.BaseAddress == null)
        {
            var baseUrl = configuration["MarketingBrain:BaseUrl"];
            if (!string.IsNullOrWhiteSpace(baseUrl))
            {
                _httpClient.BaseAddress = new Uri(baseUrl);
            }
        }
        _httpClient.Timeout = TimeSpan.FromSeconds(10); // Timeout agresivo para alta disponibilidad
    }

    public Task<bool> PingAsync() => IsAvailableAsync();

    public async Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _httpClient.GetAsync("health", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (HttpRequestException)
        {
            return false;
        }
    }

    public async Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0m)
    {
        var telemetryEvent = new
        {
            CampaignId = campaignId,
            EventType = eventType,
            Cost = cost,
            Timestamp = DateTime.UtcNow
        };

        // La ruta del endpoint de telemetría puede variar. Se asume "api/telemetry".
        try
        {
            // Fire-and-forget: no esperamos la respuesta, pero sí controlamos el fallo.
            await _httpClient.PostAsJsonAsync("api/telemetry", telemetryEvent, CancellationToken.None);
        }
        catch (Exception ex) when (ex is HttpRequestException || ex is TaskCanceledException)
        {
            // Se absorbe el error para no impactar el flujo principal, cumpliendo con el
            // principio de "Disconnected Tolerant". Se debería registrar en un log.
            // _logger.LogWarning(ex, "Fallo al emitir telemetría para la campaña {CampaignId}", campaignId);
        }
    }
}
