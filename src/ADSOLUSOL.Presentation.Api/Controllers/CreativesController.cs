using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using ADSOLUSOL.Domain.Entities;
using ADSOLUSOL.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using System.Text.RegularExpressions;

namespace ADSOLUSOL.Presentation.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CreativesController : ControllerBase
{
    private const long MaxAssetSize = 5 * 1024 * 1024;
    private const long MaxRequestSize = MaxAssetSize + 64 * 1024;
    private static readonly Regex AssetNamePattern = new("^[a-f0-9]{32}\\.(png|jpg|webp)$", RegexOptions.Compiled | RegexOptions.CultureInvariant);
    private string? TenantId => HttpContext.Items["TenantId"] as string;
    private readonly ICreativeRepository _creativeRepository;
    private readonly IWebHostEnvironment _environment;

    public CreativesController(ICreativeRepository creativeRepository, IWebHostEnvironment environment)
    {
        _creativeRepository = creativeRepository;
        _environment = environment;
    }

    [HttpPost("assets")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaxRequestSize)]
    [EnableRateLimiting("creative-uploads")]
    public async Task<IActionResult> UploadAsset([FromForm] IFormFile? file, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(TenantId)) return Forbid();
        if (file is null || file.Length == 0 || file.Length > MaxAssetSize)
            return BadRequest(new { message = "Selecciona una imagen de hasta 5 MB." });

        await using var source = file.OpenReadStream();
        var signature = new byte[12];
        var read = await source.ReadAsync(signature.AsMemory(0, signature.Length), cancellationToken);
        var (extension, contentType) = DetectImageType(signature, read);
        if (extension is null || contentType is null)
            return BadRequest(new { message = "Formato no válido. Usa PNG, JPEG o WebP." });

        var fileName = $"{Guid.NewGuid():N}.{extension}";
        var directory = Path.Combine(_environment.ContentRootPath, "App_Data", "creative-assets");
        Directory.CreateDirectory(directory);
        var destination = Path.Combine(directory, fileName);

        source.Position = 0;
        await using (var output = new FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, useAsync: true))
            await source.CopyToAsync(output, cancellationToken);

        return Ok(new { contentUrl = $"{Request.Scheme}://{Request.Host}/api/Creatives/assets/{fileName}", contentType });
    }

    [HttpGet("assets/{fileName}")]
    public IActionResult GetAsset(string fileName)
    {
        if (!AssetNamePattern.IsMatch(fileName)) return NotFound();

        var directory = Path.GetFullPath(Path.Combine(_environment.ContentRootPath, "App_Data", "creative-assets"));
        var path = Path.GetFullPath(Path.Combine(directory, fileName));
        if (!path.StartsWith(directory + Path.DirectorySeparatorChar, StringComparison.Ordinal) || !System.IO.File.Exists(path))
            return NotFound();

        Response.Headers.CacheControl = "public,max-age=31536000,immutable";
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        Response.Headers.ContentSecurityPolicy = "default-src 'none'; sandbox";
        var contentType = Path.GetExtension(fileName) switch
        {
            ".png" => "image/png",
            ".jpg" => "image/jpeg",
            ".webp" => "image/webp",
            _ => "application/octet-stream"
        };
        return PhysicalFile(path, contentType, enableRangeProcessing: true);
    }

    private static (string? Extension, string? ContentType) DetectImageType(byte[] bytes, int length)
    {
        if (length >= 8 && bytes.AsSpan(0, 8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }))
            return ("png", "image/png");
        if (length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
            return ("jpg", "image/jpeg");
        if (length >= 12 && bytes.AsSpan(0, 4).SequenceEqual("RIFF"u8) && bytes.AsSpan(8, 4).SequenceEqual("WEBP"u8))
            return ("webp", "image/webp");
        return (null, null);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromServices] AppDbContext context)
    {
        if (string.IsNullOrWhiteSpace(TenantId)) return Forbid();
        return Ok(await context.Creatives.AsNoTracking().ToListAsync());
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> GetById(long id)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        var creative = await _creativeRepository.GetByIdAsync(id);
        if (creative is null)
        {
            return NotFound();
        }
        return Ok(creative);
    }

    [HttpPost]
    public async Task<IActionResult> CreateCreative([FromBody] Creative creative)
    {
        if (string.IsNullOrWhiteSpace(TenantId))
        {
            return Forbid();
        }

        creative.CreatedAt = DateTime.UtcNow;
        creative.UpdatedAt = DateTime.UtcNow;
        var id = await _creativeRepository.CreateAsync(creative);
        var createdCreative = await _creativeRepository.GetByIdAsync(id);
        return CreatedAtAction(nameof(GetById), new { id }, createdCreative);
    }
}
