using System.Data.Common;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ADSOLUSOL.Presentation.Api.Tracking;

public sealed record TrackingCode(string Code, long CreativeId, string TargetUrl, DateTime CreatedAtUtc);

public sealed class TrackingCodeService
{
    private readonly AppDbContext _db;
    public TrackingCodeService(AppDbContext db) => _db = db;

    private async Task EnsureSchema(DbConnection connection, CancellationToken ct)
    {
        await connection.OpenAsync(ct);
        await using var command = connection.CreateCommand();
        command.CommandText = "CREATE TABLE IF NOT EXISTS TrackingCodes (Code TEXT PRIMARY KEY, TenantId TEXT NOT NULL, CreativeId INTEGER NOT NULL UNIQUE, TargetUrl TEXT NOT NULL, CreatedAtUtc TEXT NOT NULL, Clicks INTEGER NOT NULL DEFAULT 0)";
        await command.ExecuteNonQueryAsync(ct);
    }

    public async Task<TrackingCode> GetOrCreateAsync(string tenantId, long creativeId, string targetUrl, CancellationToken ct)
    {
        var connection = _db.Database.GetDbConnection();
        await EnsureSchema(connection, ct);
        await using var find = connection.CreateCommand();
        find.CommandText = "SELECT Code, TargetUrl, CreatedAtUtc FROM TrackingCodes WHERE TenantId=$tenant AND CreativeId=$creative";
        Add(find, "$tenant", tenantId); Add(find, "$creative", creativeId);
        await using var reader = await find.ExecuteReaderAsync(ct);
        if (await reader.ReadAsync(ct))
            return new(reader.GetString(0), creativeId, reader.GetString(1), DateTime.Parse(reader.GetString(2)).ToUniversalTime());
        await reader.DisposeAsync();
        var code = "ADS-" + Guid.NewGuid().ToString("N");
        var now = DateTime.UtcNow;
        await using var insert = connection.CreateCommand();
        insert.CommandText = "INSERT INTO TrackingCodes (Code,TenantId,CreativeId,TargetUrl,CreatedAtUtc) VALUES ($code,$tenant,$creative,$url,$created)";
        Add(insert, "$code", code); Add(insert, "$tenant", tenantId); Add(insert, "$creative", creativeId); Add(insert, "$url", targetUrl); Add(insert, "$created", now.ToString("O"));
        await insert.ExecuteNonQueryAsync(ct);
        return new(code, creativeId, targetUrl, now);
    }

    public Task<TrackingCode> GetOrCreateForCreativeAsync(string tenantId, long creativeId, string targetUrl, CancellationToken ct)
        => GetOrCreateAsync(tenantId, creativeId, targetUrl, ct);

    public async Task<string?> RegisterClickAsync(string code, string? userAgent, string? ip, CancellationToken ct)
    {
        var connection = _db.Database.GetDbConnection();
        await EnsureSchema(connection, ct);
        await using var command = connection.CreateCommand();
        command.CommandText = "UPDATE TrackingCodes SET Clicks=Clicks+1 WHERE Code=$code; SELECT TargetUrl FROM TrackingCodes WHERE Code=$code";
        Add(command, "$code", code);
        var value = await command.ExecuteScalarAsync(ct);
        return value as string;
    }

    private static void Add(DbCommand command, string name, object value) { var p = command.CreateParameter(); p.ParameterName = name; p.Value = value; command.Parameters.Add(p); }
}
