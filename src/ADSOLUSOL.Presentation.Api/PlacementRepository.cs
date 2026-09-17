using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class PlacementRepository : IPlacementRepository
{
    public Task<Guid> CreatePlacementAsync(string name)
    {
        return Task.FromResult(Guid.NewGuid());
    }

    public Task<string?> GetPlacementNameAsync(Guid placementId)
    {
        return Task.FromResult<string?>("Ejemplo de placement");
    }
}