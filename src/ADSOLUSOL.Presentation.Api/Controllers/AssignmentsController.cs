﻿﻿﻿using ADSOLUSOL.Domain.Interfaces;
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
    private readonly IUnitOfWork _unitOfWork;

    public AssignmentsController(IAssignmentRepository assignmentRepository, ICampaignRepository campaignRepository, IUnitOfWork unitOfWork)
    {
        _assignmentRepository = assignmentRepository;
        _campaignRepository = campaignRepository;
        _unitOfWork = unitOfWork;
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
