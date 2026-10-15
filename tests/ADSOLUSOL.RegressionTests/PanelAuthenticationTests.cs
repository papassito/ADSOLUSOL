using ADSOLUSOL.Presentation.Api.Security;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

public class PanelAuthenticationTests
{
    [Xunit.Fact]
    public void PasswordHash_VerifiesOnlyCorrectPassword()
    {
        var hash = PanelPasswordVerifier.Hash("a-long-unique-password");

        Xunit.Assert.True(PanelPasswordVerifier.Verify(hash, "a-long-unique-password"));
        Xunit.Assert.False(PanelPasswordVerifier.Verify(hash, "wrong-password"));
    }

    [Xunit.Theory]
    [Xunit.InlineData(null)]
    [Xunit.InlineData("")]
    [Xunit.InlineData("tenant-02")]
    [Xunit.InlineData("pbkdf2-sha256:1:AA==:AA==")]
    public void PasswordHash_RejectsMissingOrMalformedHashes(string? hash)
    {
        Xunit.Assert.False(PanelPasswordVerifier.Verify(hash, "any-password"));
    }

    [Xunit.Fact]
    public void SsoTicket_AcceptsValidSignatureAndClaims()
    {
        var now = DateTimeOffset.UtcNow;
        var key = RandomNumberGenerator.GetBytes(32);
        var ticket = CreateTicket(key, now.AddSeconds(60).ToUnixTimeSeconds(), new string('a', 64));

        Xunit.Assert.True(SolusolSsoTicketVerifier.TryValidate(ticket, key, now, out var claims));
        Xunit.Assert.Equal("operator@solusol.net", claims?.Email);
    }

    [Xunit.Fact]
    public void SsoTicket_RejectsInvalidSignature()
    {
        var now = DateTimeOffset.UtcNow;
        var key = RandomNumberGenerator.GetBytes(32);
        var ticket = CreateTicket(key, now.AddSeconds(60).ToUnixTimeSeconds(), new string('b', 64));

        Xunit.Assert.False(SolusolSsoTicketVerifier.TryValidate(ticket, RandomNumberGenerator.GetBytes(32), now, out _));
    }

    [Xunit.Theory]
    [Xunit.InlineData(-1)]
    [Xunit.InlineData(91)]
    public void SsoTicket_RejectsExpiredOrOverlongLifetime(int secondsFromNow)
    {
        var now = DateTimeOffset.UtcNow;
        var key = RandomNumberGenerator.GetBytes(32);
        var ticket = CreateTicket(key, now.AddSeconds(secondsFromNow).ToUnixTimeSeconds(), new string('c', 64));

        Xunit.Assert.False(SolusolSsoTicketVerifier.TryValidate(ticket, key, now, out _));
    }

    private static string CreateTicket(byte[] key, long expiry, string nonce)
    {
        var payload = JsonSerializer.SerializeToUtf8Bytes(new
        {
            email = "operator@solusol.net",
            exp = expiry,
            nonce
        });
        var encodedPayload = Convert.ToBase64String(payload).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        var signature = HMACSHA256.HashData(key, Encoding.ASCII.GetBytes(encodedPayload));
        var encodedSignature = Convert.ToBase64String(signature).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $"{encodedPayload}.{encodedSignature}";
    }
}
