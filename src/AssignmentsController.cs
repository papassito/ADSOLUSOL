using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

public record AssignmentRequest(string CampaignId, long EntityId);

[ApiController]
[Route("api/assignments")]
public class AssignmentsController : ControllerBase
{
    private string? TenantId => HttpContext.Items["TenantId"] as string;
    private readonly IAssignmentRepository _assignmentRepository;
    private readonly ICampaignRepository _campaignRepository;
    private readonly IPlacementRepository _placementRepository;
    private readonly ICreativeRepository _creativeRepository;
    private readonly IUnitOfWork _unitOfWork;

    public AssignmentsController(
        IAssignmentRepository assignmentRepository,
        ICampaignRepository campaignRepository,
        IPlacementRepository placementRepository,
        ICreativeRepository creativeRepository,
        IUnitOfWork unitOfWork)
    {
        _assignmentRepository = assignmentRepository;
        _campaignRepository = campaignRepository;
        _placementRepository = placementRepository;
        _creativeRepository = creativeRepository;
        _unitOfWork = unitOfWork;
    }

    [HttpGet]
    public async Task<IActionResult> GetAllAssignments()
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var assignments = await _assignmentRepository.GetAllAsync(TenantId);
        return Ok(assignments);
    }

    [HttpPost("creative")]
    public async Task<IActionResult> AssignCreative([FromBody] AssignmentRequest request)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var campaign = await _campaignRepository.GetByIdAsync(request.CampaignId);
        if (campaign is null || campaign.TenantId != TenantId)
        {
            return NotFound();
        }

        var creative = await _creativeRepository.GetByIdAsync(request.EntityId);
        if (creative is null)
        {
            return NotFound(new { message = $"El creativo con ID {request.EntityId} no existe." });
        }

        await _unitOfWork.BeginTransactionAsync();
        try
        {
            await _assignmentRepository.AssignCreativeToCampaignAsync(request.CampaignId, request.EntityId);
            await _unitOfWork.CommitAsync();
            return Ok();
        }
        catch
        {
            await _unitOfWork.RollbackAsync();
            return StatusCode(500, "An internal error occurred during the assignment.");
        }
    }

    [HttpPost("placement")]
    public async Task<IActionResult> AssignPlacement([FromBody] AssignmentRequest request)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var campaign = await _campaignRepository.GetByIdAsync(request.CampaignId);
        if (campaign is null || campaign.TenantId != TenantId)
        {
            return NotFound();
        }

        var allPlacements = await _placementRepository.GetAllAsync();
        var placement = allPlacements.FirstOrDefault(p => p.Id == request.EntityId);
        if (placement is null)
        {
            return NotFound(new { message = $"El placement con ID {request.EntityId} no existe." });
        }

        await _unitOfWork.BeginTransactionAsync();
        try
        {
            await _assignmentRepository.AssignPlacementToCampaignAsync(request.CampaignId, request.EntityId);
            await _unitOfWork.CommitAsync();
            return Ok();
        }
        catch
        {
            await _unitOfWork.RollbackAsync();
            return StatusCode(500, "An internal error occurred during the assignment.");
        }
    }
}
