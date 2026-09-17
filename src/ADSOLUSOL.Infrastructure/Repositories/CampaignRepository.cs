﻿﻿﻿using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Dapper;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class CampaignRepository : ICampaignRepository
{
    private readonly IConfiguration _configuration;

    public CampaignRepository(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    private IDbConnection CreateConnection() =>
        new SqliteConnection(_configuration.GetConnectionString("DefaultConnection"));

    public async Task CreateAsync(Campaign campaign)
    {
        using var connection = CreateConnection();
        var sql = @"INSERT INTO Campaigns 
            (Id, TenantId, Name, Status, Budget, BudgetSpent, CostPerMille, CostPerClick, StartDate, EndDate, CreatedAt) VALUES
            (@Id, @TenantId, @Name, @Status, @Budget, @BudgetSpent, @CostPerMille, @CostPerClick, @StartDate, @EndDate, @CreatedAt);";
        await connection.ExecuteAsync(sql, campaign);
    }

    public async Task<IEnumerable<Campaign>> GetAllAsync(string tenantId, CancellationToken token = default)
    {
        using var connection = CreateConnection();
        var sql = "SELECT * FROM Campaigns WHERE TenantId = @TenantId;";
        return await connection.QueryAsync<Campaign>(new CommandDefinition(sql, new { TenantId = tenantId }, cancellationToken: token));
    }

    public async Task<Campaign?> GetByIdAsync(Guid id)
    {
        return await GetByIdAsync(id.ToString());
    }

    public async Task<Campaign?> GetByIdAsync(string id)
    {
        using var connection = CreateConnection();
        var sql = "SELECT * FROM Campaigns WHERE Id = @Id;";
        return await connection.QueryFirstOrDefaultAsync<Campaign>(sql, new { Id = id });
    }

    public async Task UpdateAsync(Campaign campaign)
    {
        using var connection = CreateConnection();
        var sql = @"
            UPDATE Campaigns SET
                Name = @Name, Status = @Status, Budget = @Budget, BudgetSpent = @BudgetSpent,
                StartDate = @StartDate, EndDate = @EndDate
            WHERE Id = @Id AND TenantId = @TenantId;";
        await connection.ExecuteAsync(sql, campaign);
    }

    public async Task<int> UpdateBudgetAsync(string campaignId, decimal cost, IDbTransaction transaction)
    {
        if (transaction.Connection is null)
        {
            throw new InvalidOperationException("The transaction does not have an associated connection.");
        }
        var sql = "UPDATE Campaigns SET BudgetSpent = BudgetSpent + @Cost WHERE Id = @CampaignId AND BudgetSpent + @Cost <= Budget;";
        return await transaction.Connection.ExecuteAsync(sql, new { Cost = cost, CampaignId = campaignId }, transaction);
    }
}
