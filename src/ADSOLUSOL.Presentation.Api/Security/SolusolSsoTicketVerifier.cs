using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace ADSOLUSOL.Presentation.Api.Security;

public sealed record SolusolSsoClaims(
    [property: JsonPropertyName("email")] string? Email,
    [property: JsonPropertyName("exp")] long Expiry,
    [property: JsonPropertyName("nonce")] string? Nonce);

public static class SolusolSsoTicketVerifier
{
    public static bool TryValidate(
        string? ticket,
        byte[] key,
        DateTimeOffset now,
        out SolusolSsoClaims? claims)
    {
        claims = null;
        if (key.Length < 32 || string.IsNullOrWhiteSpace(ticket)) return false;

        var parts = ticket.Split('.');
        if (parts.Length != 2 || !TryDecode(parts[0], out var payload) || !TryDecode(parts[1], out var signature))
            return false;

        var expected = HMACSHA256.HashData(key, Encoding.ASCII.GetBytes(parts[0]));
        if (!CryptographicOperations.FixedTimeEquals(expected, signature)) return false;

        try
        {
            claims = JsonSerializer.Deserialize<SolusolSsoClaims>(payload);
        }
        catch (JsonException)
        {
            return false;
        }

        var currentUnix = now.ToUnixTimeSeconds();
        return !string.IsNullOrWhiteSpace(claims?.Email) &&
            claims.Expiry > currentUnix && claims.Expiry <= currentUnix + 90 &&
            claims.Nonce is { Length: 64 } && claims.Nonce.All(Uri.IsHexDigit);
    }

    private static bool TryDecode(string value, out byte[] decoded)
    {
        decoded = Array.Empty<byte>();
        var normalized = value.Replace('-', '+').Replace('_', '/');
        normalized = normalized.PadRight((normalized.Length + 3) / 4 * 4, '=');
        try
        {
            decoded = Convert.FromBase64String(normalized);
            return true;
        }
        catch (FormatException)
        {
            return false;
        }
    }
}