using System.Security.Cryptography;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace ADSOLUSOL.Presentation.Api.SiteVerification;

public sealed record SiteProof(string Domain, string SiteUrl, string Status, string Snippet,
    string? VerifiedAtUtc, string? LastCheckedAtUtc, string? Message);

public sealed class SiteVerificationService
{
    private readonly string _connectionString;
    private readonly IVerificationPageFetcher _fetcher;

    public SiteVerificationService(AppDbContext db, IVerificationPageFetcher fetcher)
    {
        _connectionString = db.Database.GetDbConnection().ConnectionString;
        _fetcher = fetcher;
    }

    private async Task<SqliteConnection> OpenAsync(CancellationToken ct)
    {
        var connection = new SqliteConnection(_connectionString);
        try
        {
            await connection.OpenAsync(ct);
            using var command = connection.CreateCommand();
            // Additive, idempotent schema: existing production databases need no destructive recreation.
            command.CommandText = @"CREATE TABLE IF NOT EXISTS SiteVerifications (
                TenantId TEXT NOT NULL, Domain TEXT NOT NULL, Token TEXT NOT NULL,
                Status TEXT NOT NULL DEFAULT 'PENDING', VerifiedAtUtc TEXT NULL,
                LastCheckedAtUtc TEXT NULL, Message TEXT NULL,
                PRIMARY KEY (TenantId, Domain))";
            await command.ExecuteNonQueryAsync(ct);
            return connection;
        }
        catch { await connection.DisposeAsync(); throw; }
    }

    public async Task<SiteProof?> GetAsync(string tenant, string targetUrl, CancellationToken ct)
    {
        var site = VerificationPolicy.GetSiteUri(targetUrl);
        await using var connection = await OpenAsync(ct);
        return await ReadAsync(connection, tenant, site, ct);
    }

    public async Task<SiteProof> GetOrCreateAsync(string tenant, string targetUrl, CancellationToken ct)
    {
        var site = VerificationPolicy.GetSiteUri(targetUrl);
        await using var connection = await OpenAsync(ct);
        using var command = connection.CreateCommand();
        command.CommandText = "INSERT INTO SiteVerifications (TenantId, Domain, Token) VALUES ($tenant, $domain, $token) ON CONFLICT(TenantId, Domain) DO NOTHING";
        command.Parameters.AddWithValue("$tenant", tenant);
        command.Parameters.AddWithValue("$domain", site.IdnHost);
        command.Parameters.AddWithValue("$token", Convert.ToHexString(RandomNumberGenerator.GetBytes(32)).ToLowerInvariant());
        await command.ExecuteNonQueryAsync(ct);
        return (await ReadAsync(connection, tenant, site, ct))!;
    }

    private static async Task<SiteProof?> ReadAsync(SqliteConnection connection, string tenant, Uri site, CancellationToken ct)
    {
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT Token, Status, VerifiedAtUtc, LastCheckedAtUtc, Message FROM SiteVerifications WHERE TenantId=$tenant AND Domain=$domain";
        command.Parameters.AddWithValue("$tenant", tenant);
        command.Parameters.AddWithValue("$domain", site.IdnHost);
        await using var reader = await command.ExecuteReaderAsync(ct);
        if (!await reader.ReadAsync(ct)) return null;
        string? Optional(int i) => reader.IsDBNull(i) ? null : reader.GetString(i);
        return new SiteProof(site.IdnHost, site.AbsoluteUri, reader.GetString(1),
            "<meta name=\"adsolusol-verification\" content=\"" + reader.GetString(0) + "\">",
            Optional(2), Optional(3), Optional(4));
    }

    public async Task<SiteProof?> VerifyAsync(string tenant, string targetUrl, CancellationToken ct)
    {
        var proof = await GetAsync(tenant, targetUrl, ct);
        if (proof is null) return null;
        var token = proof.Snippet.Split('"')[3];
        var status = "FAILED";
        var message = "No se encontró la etiqueta correcta dentro de <head>.";
        try
        {
            var html = await _fetcher.FetchAsync(new Uri(proof.SiteUrl), ct);
            if (VerificationPolicy.ContainsProof(html, token))
            {
                status = "VERIFIED";
                message = "Etiqueta comprobada en el dominio. Esto no acredita entrega ni conversiones.";
            }
        }
        catch (Exception ex) when (ex is HttpRequestException || ex is OperationCanceledException ||
            ex is System.Text.RegularExpressions.RegexMatchTimeoutException || ex is System.IO.IOException)
        {
            if (ct.IsCancellationRequested) throw;
            message = "No se pudo comprobar el sitio por HTTPS. Revisa certificado, red, tamaño y redirecciones.";
        }
        var now = DateTimeOffset.UtcNow.ToString("O");
        await using var connection = await OpenAsync(ct);
        using var command = connection.CreateCommand();
        command.CommandText = @"UPDATE SiteVerifications SET Status=$status, VerifiedAtUtc=$verified,
            LastCheckedAtUtc=$checked, Message=$message WHERE TenantId=$tenant AND Domain=$domain";
        command.Parameters.AddWithValue("$tenant", tenant);
        command.Parameters.AddWithValue("$domain", proof.Domain);
        command.Parameters.AddWithValue("$status", status);
        command.Parameters.AddWithValue("$verified", status == "VERIFIED" ? now : DBNull.Value);
        command.Parameters.AddWithValue("$checked", now);
        command.Parameters.AddWithValue("$message", message);
        await command.ExecuteNonQueryAsync(ct);
        return await ReadAsync(connection, tenant, new Uri(proof.SiteUrl), ct);
    }
}
