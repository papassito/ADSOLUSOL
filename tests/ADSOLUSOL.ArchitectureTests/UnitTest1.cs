using System.Linq;
using System.Reflection;
using NetArchTest.Rules;
using Xunit;

namespace ADSOLUSOL.ArchitectureTests;

public class DomainArchitectureTests
{
    private static readonly Assembly DomainAssembly = typeof(ADSOLUSOL.Domain.Entities.Campaign).Assembly;

    [Fact]
    public void DomainEntities_ShouldBePublicAndNotSealed()
    {
        var entityTypes = Types.InAssembly(DomainAssembly)
            .That()
            .ResideInNamespace("ADSOLUSOL.Domain.Entities")
            .And()
            .AreClasses()
            .GetTypes()
            .Where(type => !type.IsEnum && !type.IsValueType)
            .ToList();

        var invalidEntities = entityTypes
            .Where(type => !type.IsPublic || type.IsSealed)
            .Select(type => $"{type.Name} (Public: {type.IsPublic}, Sealed: {type.IsSealed})")
            .ToList();

        Assert.True(
            invalidEntities.Count == 0,
            $"Entidades del dominio no conformes (deben ser 'public' y 'non-sealed'):\n{string.Join("\n", invalidEntities)}"
        );
    }

    [Fact]
    public void Domain_ShouldNotHaveDependencyOnOtherLayers()
    {
        var forbiddenLayers = new[]
        {
            "ADSOLUSOL.Application",
            "ADSOLUSOL.Infrastructure",
            "ADSOLUSOL.Presentation.Api",
            "ADSOLUSOL.Presentation.Desktop"
        };

        var result = Types.InAssembly(DomainAssembly)
            .ShouldNot()
            .HaveDependencyOnAny(forbiddenLayers)
            .GetResult();

        Assert.True(result.IsSuccessful, "Violación detectada: ADSOLUSOL.Domain posee dependencias hacia capas externas.");
    }
}