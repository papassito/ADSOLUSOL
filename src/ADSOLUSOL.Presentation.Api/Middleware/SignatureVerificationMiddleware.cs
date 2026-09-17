using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Http;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace ADSOLUSOL.Presentation.Api.Middleware
{
    public class SignatureVerificationMiddleware
    {
        private readonly RequestDelegate _next;

        public SignatureVerificationMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, ICoreSignatureVerifier signatureVerifier)
        {
            // Rutas públicas que no requieren firma (ej. Swagger, health checks)
            if (context.Request.Path.StartsWithSegments("/swagger") || context.Request.Path.StartsWithSegments("/api/health"))
            {
                await _next(context);
                return;
            }

            var signature = context.Request.Headers["X-Signature"].FirstOrDefault();
            var nonce = context.Request.Headers["X-Nonce"].FirstOrDefault();
            var timestamp = context.Request.Headers["X-Timestamp"].FirstOrDefault();
            var nodeId = context.Request.Headers["X-Node-Id"].FirstOrDefault();

            if (string.IsNullOrEmpty(signature) || string.IsNullOrEmpty(nonce) || string.IsNullOrEmpty(timestamp) || string.IsNullOrEmpty(nodeId))
            {
                context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                await context.Response.WriteAsync("Faltan cabeceras de firma requeridas.");
                return;
            }

            context.Request.EnableBuffering();
            string body;
            using (var reader = new StreamReader(context.Request.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, leaveOpen: true))
            {
                body = await reader.ReadToEndAsync();
                context.Request.Body.Position = 0;
            }

            // El verificador devuelve la validez y el TenantId asociado al NodeId
            var (isValid, tenantId) = await signatureVerifier.VerifySignatureAndGetTenantAsync(nodeId, context.Request.Method, context.Request.Path, context.Request.QueryString.ToString(), timestamp, nonce, body, signature);

            if (!isValid || string.IsNullOrEmpty(tenantId))
            {
                context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                await context.Response.WriteAsync("Firma inválida.");
                return;
            }

            context.Items["TenantId"] = tenantId;
            await _next(context);
        }
    }
}