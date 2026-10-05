using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Domain.Enums;

namespace ADSOLUSOL.Application.Services;

public class EventProcessingService
{
    private readonly IAdEventRepository _eventRepository;
    private readonly ICampaignRepository _campaignRepository;
    private readonly IPlacementRepository _placementRepository;
    private readonly ICreativeRepository _creativeRepository;
    private readonly BudgetService _budgetService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMarketingBrainService _marketingBrainService;

    public EventProcessingService(IAdEventRepository eventRepository, ICampaignRepository campaignRepository, IPlacementRepository placementRepository, ICreativeRepository creativeRepository, BudgetService budgetService, IUnitOfWork unitOfWork, IMarketingBrainService marketingBrainService)
    {
        _eventRepository = eventRepository;
        _campaignRepository = campaignRepository;
        _placementRepository = placementRepository;
        _creativeRepository = creativeRepository;
        _budgetService = budgetService;
        _unitOfWork = unitOfWork;
        _marketingBrainService = marketingBrainService;
    }

    public async Task<EventProcessingStatus> ProcessEvent(AdEvent adEvent)
    {
        if (await _eventRepository.ExistsAsync(adEvent.EventId))
        {
            return EventProcessingStatus.Duplicate;
        }

        var placement = await _placementRepository.GetByCodeAsync(adEvent.PlacementCode);
        if (placement is null || !placement.IsEnabled)
        {
            return EventProcessingStatus.Rejected;
        }
        // Assign the real PlacementId
        adEvent.PlacementId = placement.Id.ToString();

        if (!long.TryParse(adEvent.CreativeId, out var creativeId))
        {
            return EventProcessingStatus.Rejected;
        }

        var creative = await _creativeRepository.GetByIdAsync(creativeId);
        if (creative is null || !creative.IsEnabled)
        {
            return EventProcessingStatus.Rejected;
        }

        var campaign = await _campaignRepository.GetByIdAsync(adEvent.CampaignId);
        if (campaign is null ||
            campaign.TenantId != adEvent.TenantId || // Tenant isolation validation
            campaign.Status != "ACTIVE" || // Must be active
            (campaign.Budget - campaign.BudgetSpent) <= 0 || // Must have budget
            DateTime.UtcNow < campaign.StartDateUtc || // Must have started
            DateTime.UtcNow > campaign.EndDateUtc) // Must not have ended
        {
            return EventProcessingStatus.Rejected;
        }

        // Validate associations
        var isPlacementAssociated = await _campaignRepository.IsPlacementAssociatedAsync(campaign.Id, placement.Id);
        var isCreativeAssociated = await _campaignRepository.IsCreativeAssociatedAsync(campaign.Id, creative.Id);
        if (!isPlacementAssociated || !isCreativeAssociated)
        {
            return EventProcessingStatus.Rejected;
        }

        if (!Enum.TryParse<EventType>(adEvent.EventType, true, out var eventTypeEnum))
        {
            // This case should be handled by upstream validation, but as a safeguard:
            return EventProcessingStatus.Rejected;
        }

        // FIX: Normalize event type to uppercase for consistent storage and querying.
        adEvent.EventType = eventTypeEnum.ToString().ToUpper();

        // Calculate cost once and assign it to the event object. This is the single source of truth.
        adEvent.Cost = eventTypeEnum switch
        {
            EventType.Impression => campaign.CostPerMille / 1000,
            EventType.Click => campaign.CostPerClick,
            _ => 0
        };

        await _unitOfWork.BeginTransactionAsync();
        try
        {
            await _eventRepository.AddAsync(adEvent, _unitOfWork.Transaction);

            var debitSuccessful = await _budgetService.DebitEventCost(adEvent.CampaignId, adEvent.Cost, _unitOfWork.Transaction!);
            if (!debitSuccessful)
            {
                await _unitOfWork.RollbackAsync();
                return EventProcessingStatus.Rejected; // Budget exceeded or other debit failure
            }

            await _unitOfWork.CommitAsync();

            // The cost is now correctly reported to the telemetry service.
            await _marketingBrainService.EmitTelemetryAsync(adEvent.CampaignId, $"ADS_{eventTypeEnum.ToString().ToUpper()}", adEvent.Cost);

            return EventProcessingStatus.Accepted;
        }
        catch
        {
            await _unitOfWork.RollbackAsync();
            throw;
        }
    }
}
