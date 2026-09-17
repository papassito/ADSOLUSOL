﻿﻿﻿using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Dapper;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class CreativeRepository : ICreativeRepository
{
    private readonly IConfiguration _configuration;

    public CreativeRepository(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    private IDbConnection CreateConnection() =>
        new SqliteConnection(_configuration.GetConnectionString("DefaultConnection"));

    public async Task<Creative?> GetEligibleCreativeForCampaignAsync(string campaignId)
    {
        using var connection = CreateConnection();
        var sql = @"
            SELECT c.* FROM Creatives c
            INNER JOIN CampaignCreatives cc ON c.Id = cc.CreativeId
            WHERE cc.CampaignId = @CampaignId
            LIMIT 1;";
        return await connection.QueryFirstOrDefaultAsync<Creative>(sql, new { CampaignId = campaignId });
    }

    public async Task<Creative?> GetByIdAsync(long id)
    {
        using var connection = CreateConnection();
        var sql = "SELECT * FROM Creatives WHERE Id = @Id;";
        return await connection.QueryFirstOrDefaultAsync<Creative>(sql, new { Id = id });
    }

    public async Task<long> CreateAsync(Creative creative)
    {
        using var connection = CreateConnection();
        var sql = @"
            INSERT INTO Creatives (Name, ContentUrl, TargetUrl, IsEnabled, CreatedAt, UpdatedAt)
            VALUES (@Name, @ContentUrl, @TargetUrl, @IsEnabled, @CreatedAt, @UpdatedAt);
            SELECT last_insert_rowid();";
        return await connection.ExecuteScalarAsync<long>(sql, creative);
    }
}
