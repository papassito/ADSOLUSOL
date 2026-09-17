using ADSOLUSOL.Domain.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace ADSOLUSOL.Presentation.Api.Controllers;

public record AssignmentRequest(string CampaignId, long EntityId);

[ApiController]
[Route("api/assignments")]
public class AssignmentsController : ControllerBase
{
    private readonly IAssignmentRepository _assignmentRepository;

    public AssignmentsController(IAssignmentRepository assignmentRepository)
    {
        _assignmentRepository = assignmentRepository;
    }

    [HttpPost("creative")]
    public async Task<IActionResult> AssignCreative([FromBody] AssignmentRequest request)
    {
        await _assignmentRepository.AssignCreativeToCampaignAsync(request.CampaignId, request.EntityId);
        return Ok();
    }

    [HttpPost("placement")]
    public async Task<IActionResult> AssignPlacement([FromBody] AssignmentRequest request)
    {
        await _assignmentRepository.AssignPlacementToCampaignAsync(request.CampaignId, request.EntityId);
        return Ok();
    }
}