﻿﻿﻿﻿﻿using ADSOLUSOL.Domain.Entities;
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
        var connection = _context.Database.GetDbConnection();
        var sql = "SELECT * FROM Creatives WHERE Id = @Id;";
        return await connection.QueryFirstOrDefaultAsync<Creative>(sql, new { Id = id });
    }

    public async Task<long> CreateAsync(Creative creative)
    {
        var connection = _context.Database.GetDbConnection();
        var sql = @"
            INSERT INTO Creatives (Name, ContentUrl, TargetUrl, IsEnabled, CreatedAt, UpdatedAt)
            VALUES (@Name, @ContentUrl, @TargetUrl, @IsEnabled, @CreatedAt, @UpdatedAt);
            SELECT last_insert_rowid();";
        return await connection.ExecuteScalarAsync<long>(sql, creative);
    }
}
