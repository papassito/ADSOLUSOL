using System.Net;
using System.Net.Sockets;
using System.Text.RegularExpressions;

namespace ADSOLUSOL.Presentation.Api.SiteVerification;

public static class VerificationPolicy
{
    private static readonly TimeSpan MatchTimeout = TimeSpan.FromMilliseconds(250);

    public static Uri GetSiteUri(string targetUrl)
    {
        if (string.IsNullOrWhiteSpace(targetUrl) || targetUrl.Length > 4096 ||
            !Uri.TryCreate(targetUrl, UriKind.Absolute, out var uri) ||
            uri.Scheme != Uri.UriSchemeHttps || !uri.IsDefaultPort ||
            !string.IsNullOrEmpty(uri.UserInfo) || uri.HostNameType != UriHostNameType.Dns)
            throw new ArgumentException("Usa una URL HTTPS de un dominio público, sin credenciales ni puerto personalizado.");
        var host = uri.IdnHost.ToLowerInvariant();
        if (host.EndsWith('.') || !host.Contains('.') || host.EndsWith(".localhost") ||
            host.EndsWith(".local") || host.EndsWith(".internal"))
            throw new ArgumentException("El dominio debe ser público.");
        // Verification belongs to the exact host, independent of landing path/query.
        return new Uri("https://" + host + "/");
    }

    public static Uri GetMonitorUri(string targetUrl)
    {
        var site = GetSiteUri(targetUrl);
        var target = new Uri(targetUrl);
        return new UriBuilder(site)
        {
            Path = target.AbsolutePath,
            Query = string.Empty,
            Fragment = string.Empty
        }.Uri;
    }

    public static bool IsPublicAddress(IPAddress address)
    {
        if (address.IsIPv4MappedToIPv6) address = address.MapToIPv4();
        var b = address.GetAddressBytes();
        if (address.AddressFamily == AddressFamily.InterNetwork)
        {
            return !(b[0] == 0 || b[0] == 10 || b[0] == 127 || b[0] >= 224 ||
                (b[0] == 100 && b[1] >= 64 && b[1] <= 127) ||
                (b[0] == 169 && b[1] == 254) ||
                (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
                (b[0] == 192 && (b[1] == 168 || b[1] == 0 ||
                    (b[1] == 88 && b[2] == 99))) ||
                (b[0] == 198 && (b[1] == 18 || b[1] == 19 ||
                    (b[1] == 51 && b[2] == 100))) ||
                (b[0] == 203 && b[1] == 0 && b[2] == 113));
        }
        // Only global unicast; reject documentation, Teredo and 6to4 tunnels.
        return address.AddressFamily == AddressFamily.InterNetworkV6 && (b[0] & 0xe0) == 0x20 &&
            !(b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0d && b[3] == 0xb8) &&
            !(b[0] == 0x20 && b[1] == 0x01 && b[2] == 0 && b[3] == 0) &&
            !(b[0] == 0x20 && b[1] == 0x02);
    }

    public static bool ContainsProof(string html, string token)
    {
        // Ignore comments and raw-text elements: a code example is not proof.
        var cleaned = Regex.Replace(html, @"<!--[\s\S]*?-->|<(script|style|textarea|title)\b[^>]*>[\s\S]*?</\1\s*>",
            "", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant, MatchTimeout);
        var head = Regex.Match(cleaned, @"<head\b[^>]*>([\s\S]*?)</head\s*>",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant, MatchTimeout);
        if (!head.Success) return false;
        foreach (Match tag in Regex.Matches(head.Groups[1].Value, @"<meta\b(?:[^>""']|""[^""]*""|'[^']*')*>",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant, MatchTimeout))
        {
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match attr in Regex.Matches(tag.Value, @"([^\s=<>/]+)\s*=\s*(?:""([^""]*)""|'([^']*)'|([^\s>]+))",
                RegexOptions.CultureInvariant, MatchTimeout))
            {
                var key = attr.Groups[1].Value;
                if (attributes.ContainsKey(key)) return false; // Ambiguous duplicate attributes.
                attributes[key] = WebUtility.HtmlDecode(attr.Groups[2].Success ? attr.Groups[2].Value :
                    attr.Groups[3].Success ? attr.Groups[3].Value : attr.Groups[4].Value);
            }
            if (attributes.TryGetValue("name", out var name) &&
                name.Equals("adsolusol-verification", StringComparison.OrdinalIgnoreCase) &&
                attributes.TryGetValue("content", out var content) &&
                string.Equals(content, token, StringComparison.Ordinal))
                return true;
        }
        return false;
    }
}
