using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.ValueObjects;
using System.Threading.Tasks;
using System.Threading;

namespace ADSOLUSOL.Domain.Interfaces;

/// <summary>
/// Defines the contract for the service responsible for communicating with the Marketing Brain / SIC.
/// </summary>
public interface IMarketingBrainService
{
    /// <summary>
    /// Emits a telemetry signal to the central intelligence system (SIC).
    /// </summary>
    Task EmitTelemetryAsync(string eventType, object eventPayload);

    /// <summary>
    /// Requests intelligent ad content generation from the SIC.
    /// </summary>
    Task<AdContent?> GenerateAdContentAsync(Campaign campaign, CancellationToken token = default);
}