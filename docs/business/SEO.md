# AD SOLUSOL — SEO / SUPER SEO Boundary

**Estado:** BOUNDARY / CONTEXT. SEO no forma parte del runtime ADS actual documentado aquí.

## Separación

SEO y SUPER SEO pertenecen al dominio de señales orgánicas, no al núcleo ADS.

```text
URL / Host
   ↓
SEO ENGINE
   ↓
SUPER SEO
   ↓
GROWTH

AD SOLUSOL ─────────────► GROWTH
```

Ambos flujos son paralelos.

## SEO

Responsabilidades observadas:

- fetch de dominio;
- headers;
- metatags;
- canonical;
- robots.txt;
- sitemap;
- Schema.org;
- TTFB;
- diagnóstico de indexabilidad.

## SUPER SEO

Responsabilidad planificada:

- correlacionar rendimiento/red con comportamiento orgánico;
- entregar señales a GROWTH.

## Seguridad

El crawler debe resolver DNS y bloquear loopback, redes privadas y link-local antes de efectuar la conexión, incluyendo IPv4 e IPv6 y redirecciones.

### Mitigación e Implementación del Resolver Seguro (C#)

Para prevenir ataques de Server-Side Request Forgery (SSRF), se implementa un `SocketsHttpHandler` personalizado que intercepta la resolución de DNS y valida la dirección IP de destino antes de establecer cualquier socket de conexión:

```csharp
using System;
using System.Net;
using System.Net.Sockets;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

public class SafeHttpClientHandler : SocketsHttpHandler
{
    public SafeHttpClientHandler()
    {
        // Interceptamos la conexión TCP para verificar la IP resuelta antes de conectar.
        ConnectCallback = async (context, cancellationToken) =>
        {
            var host = context.DnsEndPoint.Host;
            var port = context.DnsEndPoint.Port;

            // 1. Resolver DNS de forma asíncrona
            var ipAddresses = await Dns.GetHostAddressesAsync(host, cancellationToken);

            foreach (var ip in ipAddresses)
            {
                // 2. Validar que la IP no sea privada, loopback o link-local
                if (IsPrivateOrInternal(ip))
                {
                    throw new WebException($"Conexión bloqueada por directivas de seguridad (SSRF Detectado): {ip}", WebExceptionStatus.AccessDenied);
                }
            }

            // 3. Crear socket seguro
            var socket = new Socket(SocketType.Stream, ProtocolType.Tcp) { NoDelay = true };
            try
            {
                await socket.ConnectAsync(ipAddresses, port, cancellationToken);
                return new NetworkStream(socket, ownsSocket: true);
            }
            catch
            {
                socket.Dispose();
                throw;
            }
        };
    }

    private static bool IsPrivateOrInternal(IPAddress ip)
    {
        if (IPAddress.IsLoopback(ip)) return true;

        // Soporte IPv4 e IPv6
        byte[] bytes = ip.GetAddressBytes();
        if (ip.AddressFamily == AddressFamily.InterNetwork)
        {
            // 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16
            return bytes[0] == 10 ||
                  (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
                  (bytes[0] == 192 && bytes[1] == 168) ||
                  (bytes[0] == 169 && bytes[1] == 254);
        }
        else if (ip.AddressFamily == AddressFamily.InterNetworkV6)
        {
            // IPv6 Link-Local (fe80::/10), Loopback (::1), Unique Local (fc00::/7)
            return ip.IsIPv6LinkLocal || 
                   ip.IsIPv6UniqueLocal || 
                   IPAddress.IPv6Loopback.Equals(ip);
        }
        return false;
    }
}
```

## Estado heredado relevante

La documentación suministrada reporta:

- crawler SEO implementado;
- Sitemap Validator parcial;
- Super SEO planificado;
- FID/CLS fijos simulados en Core Web Vitals;
 - riesgo SSRF mitigado mediante la implementación de `SafeHttpClientHandler`.

Los valores simulados no forman parte de la verdad operacional de ADS.
