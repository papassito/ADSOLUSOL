using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AssignmentRepository : IAssignmentRepository
{
    private readonly AppDbContext _context;

    public AssignmentRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task AssignPlacementToCampaignAsync(string campaignId, long placementId)
    {
        var exists = await _context.CampaignPlacements.AnyAsync(cp => cp.CampaignId == campaignId && cp.PlacementId == placementId);
        if (!exists)
        {
            _context.CampaignPlacements.Add(new CampaignPlacement { CampaignId = campaignId, PlacementId = placementId });
            await _context.SaveChangesAsync();
        }
    }

    public async Task AssignCreativeToCampaignAsync(string campaignId, long creativeId)
    {
        var exists = await _context.CampaignCreatives.AnyAsync(cc => cc.CampaignId == campaignId && cc.CreativeId == creativeId);
        if (!exists)
        {
            _context.CampaignCreatives.Add(new CampaignCreative { CampaignId = campaignId, CreativeId = creativeId });
            await _context.SaveChangesAsync();
        }
    }
}