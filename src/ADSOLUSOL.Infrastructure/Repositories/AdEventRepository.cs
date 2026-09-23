using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Dapper;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AdEventRepository : IAdEventRepository
{
    private readonly AppDbContext _context;

    public AdEventRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(AdEvent adEvent, IDbTransaction? transaction = null)
    {
        // Always use the DbContext to ensure the change tracker is aware of the new entity.
        // EF Core will automatically enlist this operation in the ambient transaction if one exists.
        await _context.AdEvents.AddAsync(adEvent);
    }

    public async Task<bool> ExistsAsync(string eventId)
    {
        return await _context.AdEvents.AnyAsync(e => e.EventId == eventId);
    }

    public async Task<int> CountByTypeAsync(string campaignId, string eventType)
    {
        return await _context.AdEvents.CountAsync(e => e.CampaignId == campaignId && e.EventType == eventType);
    }
}