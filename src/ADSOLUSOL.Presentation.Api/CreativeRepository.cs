using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class CreativeRepository : ICreativeRepository
{
    public Task<Guid> CreateCreativeAsync(string content)
    {
        return Task.FromResult(Guid.NewGuid());
    }

    public Task<string?> GetCreativeContentAsync(Guid creativeId)
    {
        return Task.FromResult<string?>("Ejemplo de contenido");
    }
}