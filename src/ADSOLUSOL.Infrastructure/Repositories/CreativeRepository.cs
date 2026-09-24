using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Dapper;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class CreativeRepository : ICreativeRepository
{
    private readonly AppDbContext _context;

    public CreativeRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Creative?> GetEligibleCreativeForCampaignAsync(string campaignId)
    {
        var connection = _context.Database.GetDbConnection();
        var sql = @"
            SELECT c.* FROM Creatives c
            INNER JOIN CampaignCreatives cc ON c.Id = cc.CreativeId
            WHERE cc.CampaignId = @CampaignId AND c.IsEnabled = 1
            LIMIT 1;";
        return await connection.QueryFirstOrDefaultAsync<Creative>(sql, new { CampaignId = campaignId });
    }

    public async Task<Creative?> GetByIdAsync(long id)
    {
        return await _context.Creatives.FindAsync(id);
    }

    public async Task<long> CreateAsync(Creative creative)
    {
        _context.Creatives.Add(creative);
        await _context.SaveChangesAsync();
        return creative.Id;
    }
}
