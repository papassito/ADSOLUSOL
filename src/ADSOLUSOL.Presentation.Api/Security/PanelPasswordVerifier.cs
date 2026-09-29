using System.Security.Cryptography;
using System.Text;

namespace ADSOLUSOL.Presentation.Api.Security;

public static class PanelPasswordVerifier
{
    private const string Algorithm = "pbkdf2-sha256";
    private const int MinimumIterations = 210_000;

    // Format: pbkdf2-sha256:iterations:base64(salt):base64(hash)
    public static bool Verify(string? storedHash, string? password)
    {
        if (string.IsNullOrEmpty(storedHash) || string.IsNullOrEmpty(password))
        {
            return false;
        }

        var parts = storedHash.Split(':');
        if (parts.Length != 4 || parts[0] != Algorithm ||
            !int.TryParse(parts[1], out var iterations) || iterations < MinimumIterations)
        {
            return false;
        }

        try
        {
            var salt = Convert.FromBase64String(parts[2]);
            var expected = Convert.FromBase64String(parts[3]);
            if (salt.Length < 16 || expected.Length < 32)
            {
                return false;
            }

            var actual = Rfc2898DeriveBytes.Pbkdf2(
                Encoding.UTF8.GetBytes(password), salt, iterations,
                HashAlgorithmName.SHA256, expected.Length);
            return CryptographicOperations.FixedTimeEquals(actual, expected);
        }
        catch (FormatException)
        {
            return false;
        }
    }

    public static string Hash(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            throw new ArgumentException("Password cannot be blank.", nameof(password));
        }

        const int iterations = 310_000;
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(
            Encoding.UTF8.GetBytes(password), salt, iterations,
            HashAlgorithmName.SHA256, 32);
        return $"{Algorithm}:{iterations}:{Convert.ToBase64String(salt)}:{Convert.ToBase64String(hash)}";
    }
}
