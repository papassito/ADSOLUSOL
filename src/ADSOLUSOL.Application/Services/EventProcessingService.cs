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

        await _unitOfWork.BeginTransactionAsync();
        try 
        {
            await _eventRepository.AddAsync(adEvent, _unitOfWork.Transaction);

            if (!Enum.TryParse<EventType>(adEvent.EventType, true, out var eventTypeEnum))
            {
                // This case should be handled by upstream validation, but as a safeguard:
                await _unitOfWork.RollbackAsync();
                return EventProcessingStatus.Rejected;
            }

            await _budgetService.DebitEventCost(adEvent.CampaignId, eventTypeEnum, _unitOfWork.Transaction!, campaign);
            await _unitOfWork.CommitAsync();

            await _marketingBrainService.EmitTelemetryAsync(adEvent.CampaignId, $"ADS_{eventTypeEnum.ToString().ToUpper()}", adEvent.Cost);

            return EventProcessingStatus.Accepted;
        } catch 
        {
            await _unitOfWork.RollbackAsync();
            throw;
        }
    }
}



