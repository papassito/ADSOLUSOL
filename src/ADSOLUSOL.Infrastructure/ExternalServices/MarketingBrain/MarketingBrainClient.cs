using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;

namespace ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;

public class MarketingBrainClient : IMarketingBrainService
{
    private readonly HttpClient _httpClient;
    private readonly IServiceScopeFactory? _scopeFactory;
    private readonly ILogger<MarketingBrainClient>? _logger;

    public MarketingBrainClient(
        HttpClient httpClient,
        IConfiguration configuration,
        IServiceScopeFactory? scopeFactory = null,
        ILogger<MarketingBrainClient>? logger = null)
    {
        _httpClient = httpClient;
        _scopeFactory = scopeFactory;
        _logger = logger;
        if (_httpClient.BaseAddress == null)
        {
            var baseUrl = configuration["MarketingBrain:BaseUrl"]
                       ?? configuration["SolusolAuthV1:SicBaseUrl"];
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
        if (_httpClient.BaseAddress == null)
        {
            return false;
        }

        try
        {
            var response = await _httpClient.GetAsync("health", cancellationToken);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex) when (ex is HttpRequestException || ex is OperationCanceledException || ex is TimeoutException || ex is InvalidOperationException)
        {
            return false;
        }
    }

    public async Task EmitTelemetryAsync(string campaignId, string eventType, decimal cost = 0m)
    {
        if (_httpClient.BaseAddress == null)
        {
            return;
        }

        var telemetryEvent = new
        {
            CampaignId = campaignId,
            EventType = eventType,
            Cost = cost,
            Timestamp = DateTime.UtcNow
        };

        try
        {
            var response = await _httpClient.PostAsJsonAsync("api/telemetry", telemetryEvent, CancellationToken.None);
            if (!response.IsSuccessStatusCode)
            {
                await EnqueueOutboxAsync(campaignId, eventType, cost, telemetryEvent, $"HTTP {(int)response.StatusCode}: {response.ReasonPhrase}");
            }
        }
        catch (Exception ex) when (ex is HttpRequestException || ex is OperationCanceledException || ex is TimeoutException || ex is InvalidOperationException)
        {
            _logger?.LogWarning(ex, "Fallo al emitir telemetría al SIC para campaña {CampaignId}. Encolando en TelemetryOutbox.", campaignId);
            await EnqueueOutboxAsync(campaignId, eventType, cost, telemetryEvent, ex.Message);
        }
    }

    private async Task EnqueueOutboxAsync(string campaignId, string eventType, decimal cost, object telemetryEvent, string reason)
    {
        if (_scopeFactory == null) return;
        try
        {
            using var scope = _scopeFactory.CreateScope();
            var dbContext = scope.ServiceProvider.GetService<AppDbContext>();
            if (dbContext != null)
            {
                var outboxEntry = new TelemetryOutbox
                {
                    CampaignId = campaignId,
                    EventType = eventType,
                    Cost = cost,
                    PayloadJson = JsonSerializer.Serialize(telemetryEvent),
                    Status = nameof(TelemetryOutboxStatus.PENDING),
                    CreatedAtUtc = DateTime.UtcNow,
                    NextAttemptUtc = DateTime.UtcNow.AddSeconds(15),
                    LastError = reason
                };

                dbContext.TelemetryOutbox.Add(outboxEntry);
                await dbContext.SaveChangesAsync(CancellationToken.None);
            }
        }
        catch (Exception ex)
        {
            _logger?.LogError(ex, "Error al persistir evento en TelemetryOutbox para campaña {CampaignId}", campaignId);
        }
    }
}
