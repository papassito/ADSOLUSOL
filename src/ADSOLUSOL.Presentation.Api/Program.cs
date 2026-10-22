using ADSOLUSOL.Presentation.Api.SiteVerification;
using ADSOLUSOL.Application.Interfaces;
using ADSOLUSOL.Application.Services;
using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.ExternalServices.MarketingBrain;
using ADSOLUSOL.Infrastructure.Security;
using ADSOLUSOL.Presentation.Api.Middleware;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.RateLimiting;
using ADSOLUSOL.Presentation.Api.Security;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.RateLimiting;
using System.Collections.Concurrent;

var usedSolusolSsoNonces = new ConcurrentDictionary<string, DateTimeOffset>(StringComparer.Ordinal);
var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Data Source=App_Data/adsolusol.db";

var appDataDir = Path.Combine(builder.Environment.ContentRootPath, "App_Data");
if (!Directory.Exists(appDataDir))
{
    Directory.CreateDirectory(appDataDir);
}

var dataProtectionDir = Path.Combine(appDataDir, "keys");
Directory.CreateDirectory(dataProtectionDir);
builder.Services.AddDataProtection()
    .SetApplicationName("ADSOLUSOL.Panel")
    .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionDir));

builder.Services.AddAuthentication("PanelCookie")
    .AddCookie("PanelCookie", options =>
    {
        options.Cookie.Name = "ADSOLUSOL.Panel";
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Strict;
        options.Cookie.Path = "/api";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.SlidingExpiration = false;
        options.Events.OnRedirectToLogin = context =>
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            return Task.CompletedTask;
        };
        options.Events.OnValidatePrincipal = context =>
        {
            var tenantId = context.Principal?.FindFirstValue("tenant_id");
            var configuration = context.HttpContext.RequestServices.GetRequiredService<IConfiguration>();
            if (string.IsNullOrWhiteSpace(tenantId) ||
                string.IsNullOrWhiteSpace(PanelAuthConfiguration.GetPasswordHash(configuration, tenantId)))
                context.RejectPrincipal();
            return Task.CompletedTask;
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("panel-login", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(15),
                QueueLimit = 0,
                AutoReplenishment = true
            }));
    options.AddPolicy("creative-uploads", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 20,
                Window = TimeSpan.FromHours(1),
                QueueLimit = 0,
                AutoReplenishment = true
            }));
    options.AddPolicy("site-verification", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 12, Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0, AutoReplenishment = true
            }));
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

// Configuración de la base de datos de la API
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(connectionString));

// Registro de Repositorios del Dominio
builder.Services.AddScoped<ICampaignRepository, CampaignRepository>();
builder.Services.AddScoped<IPlacementRepository, PlacementRepository>();
builder.Services.AddScoped<ICreativeRepository, CreativeRepository>();
builder.Services.AddScoped<IAssignmentRepository, AssignmentRepository>();
builder.Services.AddScoped<IAdEventRepository, AdEventRepository>();
builder.Services.AddScoped<ITenantSettingsRepository, TenantSettingsRepository>();
builder.Services.AddSingleton<ICoreSignatureVerifier, CoreSignatureVerifier>();
builder.Services.AddSingleton(new ConcurrentDictionary<string, DateTime>());
builder.Services.AddSingleton<INodeRegistry, NodeRegistry>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// Registro de Servicios de Aplicación
builder.Services.AddScoped<CampaignService>();
builder.Services.AddScoped<AdServingService>();
builder.Services.AddScoped<BudgetService>();
builder.Services.AddScoped<EventProcessingService>();
builder.Services.AddScoped<MetricsService>();
builder.Services.AddScoped<SiteVerificationService>();
builder.Services.AddSingleton<IVerificationPageFetcher, VerificationPageFetcher>();
builder.Services.AddScoped<ITenantSettingsService, TenantSettingsService>();

// Integración con Marketing Brain
builder.Services.AddScoped<IMarketingBrainService, MarketingBrainClient>();

// Clientes e infraestructura de soporte
builder.Services.AddHttpClient();
builder.Services.AddMemoryCache();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// --- CONFIGURACIÓN PARA PRODUCCIÓN ---
// 1. Política CORS para permitir peticiones desde el frontend web
builder.Services.AddCors(options =>
{
    options.AddPolicy("ProductionCorsPolicy", policy =>
    {
        policy.WithOrigins("https://adsolusol.solusol.net")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// 2. Configuración para operar detrás de un reverse proxy (Nginx, IIS, etc.)
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    // Limpiar redes y proxies por defecto para permitir cabeceras forwarded desde el proxy inverso
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

var app = builder.Build();
var panelIndexPath = Path.Combine(builder.Environment.ContentRootPath, "panel", "index.html");

// Inicialización de esquema SQLite en desarrollo o cuando se solicite por configuración/entorno
var shouldInitSchema = app.Environment.IsDevelopment()
    || string.Equals(Environment.GetEnvironmentVariable("INIT_SQLITE_SCHEMA"), "true", StringComparison.OrdinalIgnoreCase)
    || builder.Configuration.GetValue<bool>("INIT_SQLITE_SCHEMA");

if (shouldInitSchema)
{
    using (var scope = app.Services.CreateScope())
    {
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        dbContext.Database.EnsureCreated();
    }
}

// El middleware de ForwardedHeaders debe ir antes de redirecciones o autenticación
app.UseForwardedHeaders();
app.UseMiddleware<ExceptionMiddleware>();
app.UseRouting();
app.UseRateLimiter();
app.UseAuthentication();

app.UseSwagger();
app.UseSwaggerUI();

if (!app.Environment.IsDevelopment())
{
    app.UseCors("ProductionCorsPolicy");
}

// Liveness check básico previo al middleware de firma
app.Use(async (context, next) =>
{
    if (context.Request.Path.Equals("/api/health", StringComparison.OrdinalIgnoreCase))
    {
        await next();
        return;
    }
    if (context.Request.Path.Equals("/health", StringComparison.OrdinalIgnoreCase))
    {
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { status = "Healthy", timestamp = DateTime.UtcNow });
        return;
    }
    await next();
});

// Respuesta de estado para la raíz de la API (evita redirección 302 hacia Swagger)
app.MapGet("/", () => Results.Ok(new
{
    service = "ADSOLUSOL Sovereign Ad Server API",
    status = "ONLINE"
}));

app.MapGet("/api/panel", (HttpContext context) =>
{
    if (string.IsNullOrWhiteSpace(context.Items["TenantId"] as string))
        return Results.Unauthorized();
    return File.Exists(panelIndexPath)
        ? Results.File(panelIndexPath, "text/html; charset=utf-8")
        : Results.NotFound();
});

app.UseMiddleware<SignatureVerificationMiddleware>();
app.UseAuthorization();

app.MapPost("/api/auth/session", async (HttpContext context, IConfiguration configuration) =>
{
    if (!app.Environment.IsDevelopment() &&
        !string.Equals(context.Request.Headers.Origin.ToString(), "https://adsolusol.solusol.net", StringComparison.OrdinalIgnoreCase))
        return Results.StatusCode(StatusCodes.Status403Forbidden);

    PanelLoginRequest? login;
    try { login = await context.Request.ReadFromJsonAsync<PanelLoginRequest>(); }
    catch (JsonException) { return Results.BadRequest(new { error = "Invalid JSON." }); }

    var suppliedTenant = login?.TenantId?.Trim();
    var tenantId = configuration[$"PanelAuth:Aliases:{suppliedTenant}"] ?? suppliedTenant;
    if (tenantId is null || !Regex.IsMatch(tenantId, "^[A-Za-z0-9_-]{1,64}$") ||
        !PanelPasswordVerifier.Verify(PanelAuthConfiguration.GetPasswordHash(configuration, tenantId), login?.Password))
        return Results.Unauthorized();

    var identity = new ClaimsIdentity(new[] { new Claim("tenant_id", tenantId) }, "PanelCookie");
    await context.SignInAsync("PanelCookie", new ClaimsPrincipal(identity));
    return Results.Ok(new { status = "AUTHENTICATED", tenantId });
}).RequireRateLimiting("panel-login");

app.MapPost("/api/auth/solusol-sso", async (HttpContext context, IConfiguration configuration) =>
{
    if (!string.Equals(context.Request.Headers.Origin.ToString(), "https://solusol.net", StringComparison.OrdinalIgnoreCase))
        return Results.StatusCode(StatusCodes.Status403Forbidden);

    var form = await context.Request.ReadFormAsync();
    var keyPath = configuration["ADSOLUSOL_SSO_KEY_FILE"] ?? "/etc/solusol-sso.key";
    byte[] signingKey;
    try
    {
        signingKey = Encoding.UTF8.GetBytes((await File.ReadAllTextAsync(keyPath)).Trim());
    }
    catch (IOException)
    {
        return Results.StatusCode(StatusCodes.Status503ServiceUnavailable);
    }
    catch (UnauthorizedAccessException)
    {
        return Results.StatusCode(StatusCodes.Status503ServiceUnavailable);
    }

    if (!SolusolSsoTicketVerifier.TryValidate(form["ticket"].ToString(), signingKey, DateTimeOffset.UtcNow, out var ticket))
        return Results.Unauthorized();

    var now = DateTimeOffset.UtcNow;
    foreach (var entry in usedSolusolSsoNonces)
        if (entry.Value <= now) usedSolusolSsoNonces.TryRemove(entry.Key, out _);

    if (!usedSolusolSsoNonces.TryAdd(ticket!.Nonce!, DateTimeOffset.FromUnixTimeSeconds(ticket.Expiry)))
        return Results.Unauthorized();

    var allowedEmail = configuration["ADSOLUSOL_SSO_EMAIL"];
    var tenantId = configuration["ADSOLUSOL_SSO_TENANT_ID"];
    if (string.IsNullOrWhiteSpace(allowedEmail) ||
        !string.Equals(ticket.Email, allowedEmail, StringComparison.OrdinalIgnoreCase) ||
        string.IsNullOrWhiteSpace(tenantId) ||
        !Regex.IsMatch(tenantId, "^[A-Za-z0-9_-]{1,64}$") ||
        string.IsNullOrWhiteSpace(PanelAuthConfiguration.GetPasswordHash(configuration, tenantId)))
        return Results.Unauthorized();

    var identity = new ClaimsIdentity(new[] { new Claim("tenant_id", tenantId) }, "PanelCookie");
    await context.SignInAsync("PanelCookie", new ClaimsPrincipal(identity));
    return Results.Redirect("https://solusol.net/dashboard?adsolusol=connected");
}).RequireRateLimiting("panel-login");

app.MapGet("/api/auth/session", (HttpContext context) =>
{
    var tenantId = context.User.FindFirstValue("tenant_id");
    return context.User.Identity?.IsAuthenticated == true && !string.IsNullOrWhiteSpace(tenantId)
        ? Results.Ok(new { status = "AUTHENTICATED", tenantId }) : Results.Unauthorized();
});

app.MapDelete("/api/auth/session", async (HttpContext context) =>
{
    await context.SignOutAsync("PanelCookie");
    return Results.NoContent();
});
app.MapControllers();

app.Run();

public sealed record PanelLoginRequest(string? TenantId, string? Password);
