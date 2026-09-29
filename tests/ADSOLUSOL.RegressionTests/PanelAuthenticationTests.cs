using ADSOLUSOL.Presentation.Api.Security;

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
}
