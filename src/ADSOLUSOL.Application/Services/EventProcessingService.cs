using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Domain.Enums;

namespace ADSOLUSOL.Application.Services;

public class EventProcessingService
{
    private readonly IAdEventRepository _eventRepository;
    private readonly ICampaignRepository _campaignRepository;
    private readonly BudgetService _budgetService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMarketingBrainService _marketingBrainService;

    public EventProcessingService(IAdEventRepository eventRepository, ICampaignRepository campaignRepository, BudgetService budgetService, IUnitOfWork unitOfWork, IMarketingBrainService marketingBrainService)
    {
        _eventRepository = eventRepository;
        _campaignRepository = campaignRepository;
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

        var campaign = await _campaignRepository.GetByIdAsync(adEvent.CampaignId);
        if (campaign is null || campaign.Status != "ACTIVE" || (campaign.Budget - campaign.BudgetSpent) <= 0)
        {
            return EventProcessingStatus.Rejected;
        }

        if (!Enum.TryParse<EventType>(adEvent.EventType, true, out var eventTypeEnum))
        {
            // This case should be handled by upstream validation, but as a safeguard:
            return EventProcessingStatus.Rejected;
        }

        // FIX P1-03: Calculate cost and assign it to the event object before processing.
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

            var debitSuccessful = await _budgetService.DebitEventCost(adEvent.CampaignId, eventTypeEnum, _unitOfWork.Transaction!, campaign);
            if (!debitSuccessful)
            {
                await _unitOfWork.RollbackAsync();
                return EventProcessingStatus.Rejected; // Budget exceeded or other debit failure
            }
            
            await _unitOfWork.CommitAsync();

            // The cost is now correctly reported to the telemetry service.
            await _marketingBrainService.EmitTelemetryAsync(adEvent.CampaignId, $"ADS_{eventTypeEnum.ToString().ToUpper()}", adEvent.Cost);

            return EventProcessingStatus.Accepted;
        } catch 
        {
            await _unitOfWork.RollbackAsync();
            throw;
        }
    }
}
