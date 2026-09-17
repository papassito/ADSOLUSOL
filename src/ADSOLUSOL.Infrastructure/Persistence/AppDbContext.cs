using System.Globalization;
using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Domain.Entities;
using Microsoft.Data.Sqlite;

namespace ADSOLUSOL.Infrastructure.Persistence;

// Scoped unit of work. A single SaveChanges call commits its entire batch atomically.
public sealed class AppDbContext(string databasePath) : IAppDbContext
{
    private readonly string _databasePath = Path.GetFullPath(databasePath);
    private readonly List<Campaign> _pending = [];

    private async Task<SqliteConnection> OpenAsync(CancellationToken token)
    {
        token.ThrowIfCancellationRequested();
        Directory.CreateDirectory(Path.GetDirectoryName(_databasePath)!);
        var connection = new SqliteConnection(new SqliteConnectionStringBuilder
        {
            DataSource = _databasePath,
            Mode = SqliteOpenMode.ReadWriteCreate,
            DefaultTimeout = 5
        }.ToString());
        try
        {
            await connection.OpenAsync(token);
            using var command = connection.CreateCommand();
            command.CommandText = """
                CREATE TABLE IF NOT EXISTS campaigns (
                    id TEXT NOT NULL,
                    tenant_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    budget TEXT NOT NULL,
                    status TEXT NOT NULL CHECK(status IN ('SCHEDULED','ACTIVE','PAUSED','COMPLETED')),
                    created_at TEXT NOT NULL,
                    PRIMARY KEY (tenant_id, id)
                );
                """;
            await command.ExecuteNonQueryAsync(token);
            return connection;
        }
        catch { await connection.DisposeAsync(); throw; }
    }

    public async Task<bool> IsAvailableAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = await OpenAsync(cancellationToken);
            using var transaction = connection.BeginTransaction();
            using var command = connection.CreateCommand();
            command.Transaction = transaction;
            command.CommandText = "UPDATE campaigns SET name = name WHERE 0; SELECT COUNT(*) FROM campaigns;";
            await command.ExecuteScalarAsync(cancellationToken);
            transaction.Rollback();
            return true;
        }
        catch (Exception e) when (e is SqliteException or IOException or UnauthorizedAccessException) { return false; }
    }

    public void AddCampaign(Campaign campaign)
    {
        ArgumentNullException.ThrowIfNull(campaign);
        if (campaign.Id == Guid.Empty || string.IsNullOrWhiteSpace(campaign.TenantId) || string.IsNullOrWhiteSpace(campaign.Name) || campaign.Name.Length > 200 || campaign.Budget <= 0)
            throw new ArgumentException("A campaign requires an ID, tenant, name (1-200 characters), and positive budget.");
        _pending.Add(new Campaign { Id = campaign.Id, TenantId = campaign.TenantId, Name = campaign.Name, Budget = campaign.Budget, Status = campaign.Status, CreatedAt = campaign.CreatedAt });
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (_pending.Count == 0) return 0;
        await using var connection = await OpenAsync(cancellationToken);
        using var transaction = connection.BeginTransaction();
        foreach (var campaign in _pending)
        {
            using var command = connection.CreateCommand();
            command.Transaction = transaction;
            command.CommandText = "INSERT INTO campaigns (id, tenant_id, name, budget, status, created_at) VALUES ($id, $tenant, $name, $budget, $status, $created);";
            command.Parameters.AddWithValue("$id", campaign.Id.ToString());
            command.Parameters.AddWithValue("$tenant", campaign.TenantId);
            command.Parameters.AddWithValue("$name", campaign.Name);
            command.Parameters.AddWithValue("$budget", campaign.Budget.ToString(CultureInfo.InvariantCulture));
            command.Parameters.AddWithValue("$status", campaign.Status);
            command.Parameters.AddWithValue("$created", campaign.CreatedAt.ToUniversalTime().ToString("O"));
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        cancellationToken.ThrowIfCancellationRequested();
        transaction.Commit();
        var saved = _pending.Count;
        _pending.Clear();
        return saved;
    }

    public Task<IReadOnlyList<Campaign>> GetCampaignsAsync(string tenantId, CancellationToken cancellationToken = default)
        => QueryAsync(tenantId, null, cancellationToken);

    public async Task<Campaign?> GetCampaignAsync(string tenantId, Guid id, CancellationToken cancellationToken = default)
        => (await QueryAsync(tenantId, id, cancellationToken)).SingleOrDefault();

    private async Task<IReadOnlyList<Campaign>> QueryAsync(string tenantId, Guid? id, CancellationToken token)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(tenantId);
        await using var connection = await OpenAsync(token);
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id, tenant_id, name, budget, status, created_at FROM campaigns WHERE tenant_id = $tenant" +
            (id.HasValue ? " AND id = $id" : " ORDER BY created_at, id") + ";";
        command.Parameters.AddWithValue("$tenant", tenantId);
        if (id.HasValue) command.Parameters.AddWithValue("$id", id.Value.ToString());
        await using var reader = await command.ExecuteReaderAsync(token);
        var result = new List<Campaign>();
        while (await reader.ReadAsync(token))
            result.Add(new Campaign
            {
                Id = Guid.Parse(reader.GetString(0)), TenantId = reader.GetString(1), Name = reader.GetString(2),
                Budget = decimal.Parse(reader.GetString(3), CultureInfo.InvariantCulture), Status = reader.GetString(4),
                CreatedAt = DateTime.Parse(reader.GetString(5), CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind)
            });
        return result;
    }
}
