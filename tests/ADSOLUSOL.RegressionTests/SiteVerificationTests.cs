using System.Net;
using ADSOLUSOL.Infrastructure.Persistence;
using ADSOLUSOL.Presentation.Api.SiteVerification;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace ADSOLUSOL.RegressionTests;

public sealed class SiteVerificationTests : IDisposable
{
    private readonly string _path = Path.Combine(Path.GetTempPath(), "adsolusol-proof-" + Guid.NewGuid().ToString("N") + ".db");
    private readonly AppDbContext _db;
    private readonly StubFetcher _fetcher = new();
    private readonly SiteVerificationService _service;

    public SiteVerificationTests()
    {
        _db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite("Data Source=" + _path + ";Pooling=False").Options);
        _service = new SiteVerificationService(_db, _fetcher);
    }

    public void Dispose()
    {
        _db.Dispose();
        if (File.Exists(_path)) File.Delete(_path);
    }

    [Theory]
    [InlineData("http://example.com")]
    [InlineData("https://localhost")]
    [InlineData("https://host.local")]
    [InlineData("https://127.0.0.1")]
    [InlineData("https://[::1]")]
    [InlineData("https://user:pass@example.com")]
    [InlineData("https://example.com:8443")]
    [InlineData("file:///etc/passwd")]
    public void InvalidTargetsAreRejected(string target)
        => Assert.Throws<ArgumentException>(() => VerificationPolicy.GetSiteUri(target));

    [Theory]
    [InlineData("127.0.0.1")]
    [InlineData("10.1.1.1")]
    [InlineData("169.254.169.254")]
    [InlineData("172.16.0.1")]
    [InlineData("192.168.1.1")]
    [InlineData("100.64.0.1")]
    [InlineData("0.0.0.0")]
    [InlineData("224.0.0.1")]
    [InlineData("198.18.0.1")]
    [InlineData("::1")]
    [InlineData("fc00::1")]
    [InlineData("fe80::1")]
    [InlineData("::ffff:127.0.0.1")]
    [InlineData("2001:db8::1")]
    [InlineData("2002:7f00:1::")]
    public void InternalAndReservedAddressesAreRejected(string address)
        => Assert.False(VerificationPolicy.IsPublicAddress(IPAddress.Parse(address)));

    [Theory]
    [InlineData("8.8.8.8")]
    [InlineData("1.1.1.1")]
    [InlineData("2606:4700:4700::1111")]
    public void PublicAddressesAreAccepted(string address)
        => Assert.True(VerificationPolicy.IsPublicAddress(IPAddress.Parse(address)));

    [Fact]
    public async Task CodeIsPersistentReusedForLandingsAndScopedToExactHost()
    {
        var first = await _service.GetOrCreateAsync("owner", "https://EXAMPLE.com/landing?gclid=test", default);
        var again = await _service.GetOrCreateAsync("owner", "https://example.com/other", default);
        Assert.Equal(first.Snippet, again.Snippet);
        Assert.Equal("https://example.com/", first.SiteUrl);
        Assert.Equal("PENDING", first.Status);
        Assert.Null(first.VerifiedAtUtc);
        Assert.Equal(0, _fetcher.Calls);
        Assert.NotEqual(first.Snippet, (await _service.GetOrCreateAsync("owner", "https://www.example.com", default)).Snippet);
        Assert.NotEqual(first.Snippet, (await _service.GetOrCreateAsync("other-owner", "https://example.com", default)).Snippet);
        using var reopened = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite("Data Source=" + _path + ";Pooling=False").Options);
        var restarted = new SiteVerificationService(reopened, _fetcher);
        Assert.Equal(first.Snippet, (await restarted.GetAsync("owner", "https://example.com", default))!.Snippet);
    }

    [Fact]
    public async Task OnlyMatchingTagVerifiesAndRemovalRevokesStatus()
    {
        var proof = await _service.GetOrCreateAsync("owner", "https://example.com/landing", default);
        _fetcher.Html = "<html><head>" + proof.Snippet + "</head><body></body></html>";
        var verified = await _service.VerifyAsync("owner", proof.SiteUrl, default);
        Assert.Equal("VERIFIED", verified!.Status);
        Assert.NotNull(verified.VerifiedAtUtc);
        Assert.NotNull(verified.LastCheckedAtUtc);
        _fetcher.Html = "<html><head></head><body></body></html>";
        var removed = await _service.VerifyAsync("owner", proof.SiteUrl, default);
        Assert.Equal("FAILED", removed!.Status);
        Assert.Null(removed.VerifiedAtUtc);
    }

    [Fact]
    public async Task NetworkFailureCannotProduceVerifiedStatus()
    {
        var proof = await _service.GetOrCreateAsync("owner", "https://example.com", default);
        _fetcher.Fail = true;
        var result = await _service.VerifyAsync("owner", proof.SiteUrl, default);
        Assert.Equal("FAILED", result!.Status);
        Assert.Null(result.VerifiedAtUtc);
        Assert.Null(await _service.VerifyAsync("unknown-owner", proof.SiteUrl, default));
        Assert.Equal(1, _fetcher.Calls);
    }

    [Fact]
    public async Task AvailabilityCheckPersistsStatusAndMonitorsLandingPathWithoutQuery()
    {
        var result = await _service.CheckAvailabilityAsync("owner", "https://example.com/landing?token=private", default);
        Assert.Equal("AVAILABLE", result.Status);
        Assert.Equal("https://example.com/landing", result.Url);
        Assert.NotNull(result.ResponseTimeMs);

        using var reopened = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite("Data Source=" + _path + ";Pooling=False").Options);
        var restarted = new SiteVerificationService(reopened, _fetcher);
        var stored = await restarted.GetAvailabilityAsync("owner", "https://example.com/landing", default);
        Assert.Equal(result, stored);
    }

    [Fact]
    public async Task AvailabilityCheckStoresNetworkFailureWithoutClaimingSiteIsUp()
    {
        _fetcher.Fail = true;
        var result = await _service.CheckAvailabilityAsync("owner", "https://example.com", default);
        Assert.Equal("UNAVAILABLE", result.Status);
        Assert.Null(await _service.GetAvailabilityAsync("other-owner", "https://example.com", default));
    }

    [Theory]
    [InlineData("<head><meta content='abc' name='ADSOLUSOL-VERIFICATION'></head>", true)]
    [InlineData("<head><meta name=adsolusol-verification content=abc></head>", true)]
    [InlineData("<head><meta name='adsolusol-verification' content='abcd'></head>", false)]
    [InlineData("<head><!-- <meta name='adsolusol-verification' content='abc'> --></head>", false)]
    [InlineData("<head><script>const example = \"<meta name='adsolusol-verification' content='abc'>\";</script></head>", false)]
    [InlineData("<head></head><body><meta name='adsolusol-verification' content='abc'></body>", false)]
    [InlineData("<head><meta name='adsolusol-verification' content='wrong' content='abc'></head>", false)]
    public void ProofMustBeActualMatchingHeadTag(string html, bool expected)
        => Assert.Equal(expected, VerificationPolicy.ContainsProof(html, "abc"));

    private sealed class StubFetcher : IVerificationPageFetcher
    {
        public string Html { get; set; } = "<head></head>";
        public bool Fail { get; set; }
        public int Calls { get; private set; }
        public Task<string> FetchAsync(Uri uri, CancellationToken ct)
        {
            Calls++;
            if (Fail) throw new HttpRequestException("Synthetic network failure");
            return Task.FromResult(Html);
        }
    }
}
