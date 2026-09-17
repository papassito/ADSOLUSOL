using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AdEventRepository : IAdEventRepository
{
    private readonly AppDbContext _context;

    public AdEventRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task CreateAsync(AdEvent adEvent)
    {
        await _context.AdEvents.AddAsync(adEvent);
    }

    public async Task<bool> ExistsAsync(string eventId)
    {
        return await _context.AdEvents.AnyAsync(e => e.EventId == eventId);
    }
}