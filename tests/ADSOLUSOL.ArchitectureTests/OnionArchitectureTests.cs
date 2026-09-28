using System.Reflection;
using Xunit;

namespace ADSOLUSOL.ArchitectureTests;

public class OnionArchitectureTests
{
    private static readonly Assembly DomainAssembly = typeof(ADSOLUSOL.Domain.Entities.Campaign).Assembly;
    private static readonly Assembly ApplicationAssembly = typeof(ADSOLUSOL.Application.Services.CampaignService).Assembly;

    [Fact]
    public void Domain_ShouldNotReference_Infrastructure_Or_Presentation()
    {
        var referenced = DomainAssembly.GetReferencedAssemblies();

        var forbiddenPrefixes = new[]
        {
            "ADSOLUSOL.Infrastructure",
            "ADSOLUSOL.Presentation.Api",
            "ADSOLUSOL.Presentation.Desktop",
            "ADSOLUSOL.Presentation.Web",
            "ADSOLUSOL.Presentation.Cmd"
        };

        foreach (var prefix in forbiddenPrefixes)
        {
            Assert.DoesNotContain(
                referenced,
                r => r.Name != null && r.Name.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
            );
        }
    }

    [Fact]
    public void Application_ShouldNotReference_Presentation()
    {
        var referenced = ApplicationAssembly.GetReferencedAssemblies();

        var forbiddenPrefixes = new[]
        {
            "ADSOLUSOL.Presentation.Api",
            "ADSOLUSOL.Presentation.Desktop",
            "ADSOLUSOL.Presentation.Web",
            "ADSOLUSOL.Presentation.Cmd"
        };

        foreach (var prefix in forbiddenPrefixes)
        {
            Assert.DoesNotContain(
                referenced,
                r => r.Name != null && r.Name.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
            );
        }
    }
}