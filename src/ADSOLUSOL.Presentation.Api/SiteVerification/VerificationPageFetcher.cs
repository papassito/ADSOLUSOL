using System.Net;
using System.Net.Sockets;
using System.Text;

namespace ADSOLUSOL.Presentation.Api.SiteVerification;

public interface IVerificationPageFetcher
{
    Task<string> FetchAsync(Uri uri, CancellationToken cancellationToken);
}

public sealed class VerificationPageFetcher : IVerificationPageFetcher
{
    private const int MaxBytes = 512 * 1024;

    public async Task<string> FetchAsync(Uri uri, CancellationToken cancellationToken)
    {
        // A separate bounded client sends no cookies, secrets or authentication headers.
        using var handler = new SocketsHttpHandler
        {
            AllowAutoRedirect = false,
            UseProxy = false,
            UseCookies = false,
            ConnectTimeout = TimeSpan.FromSeconds(5),
            ConnectCallback = async (context, ct) =>
            {
                var addresses = await Dns.GetHostAddressesAsync(context.DnsEndPoint.Host, ct);
                if (addresses.Length == 0 || addresses.Any(ip => !VerificationPolicy.IsPublicAddress(ip)))
                    throw new HttpRequestException("El dominio resuelve a una dirección no permitida.");
                // Connect directly to the validated addresses. DNS is not resolved again.
                foreach (var address in addresses)
                {
                    var socket = new Socket(address.AddressFamily, SocketType.Stream, ProtocolType.Tcp);
                    try
                    {
                        await socket.ConnectAsync(new IPEndPoint(address, context.DnsEndPoint.Port), ct);
                        return new NetworkStream(socket, ownsSocket: true);
                    }
                    catch (SocketException) { socket.Dispose(); }
                    catch { socket.Dispose(); throw; }
                }
                throw new HttpRequestException("No fue posible conectar con el dominio.");
            }
        };
        using var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(10) };
        using var deadline = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        deadline.CancelAfter(TimeSpan.FromSeconds(10));
        using var request = new HttpRequestMessage(HttpMethod.Get, uri);
        request.Headers.UserAgent.ParseAdd("ADSOLUSOL-SiteVerifier/1.0");
        request.Headers.Accept.ParseAdd("text/html");
        using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, deadline.Token);
        if ((int)response.StatusCode >= 300 && (int)response.StatusCode < 400)
            throw new HttpRequestException("El sitio redirige. Usa el dominio final exacto del anuncio.");
        response.EnsureSuccessStatusCode();
        var mediaType = response.Content.Headers.ContentType?.MediaType;
        if (mediaType != "text/html" && mediaType != "application/xhtml+xml")
            throw new HttpRequestException("El sitio no respondió con HTML.");
        if (response.Content.Headers.ContentLength > MaxBytes)
            throw new HttpRequestException("La página supera el límite de 512 KB.");
        await using var input = await response.Content.ReadAsStreamAsync(deadline.Token);
        using var output = new MemoryStream();
        var buffer = new byte[8192];
        int read;
        while ((read = await input.ReadAsync(buffer.AsMemory(), deadline.Token)) > 0)
        {
            if (output.Length + read > MaxBytes)
                throw new HttpRequestException("La página supera el límite de 512 KB.");
            output.Write(buffer, 0, read);
        }
        return Encoding.UTF8.GetString(output.ToArray());
    }
}
