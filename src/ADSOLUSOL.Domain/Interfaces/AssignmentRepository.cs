using ADSOLUSOL.Domain.Interfaces;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class AssignmentRepository : IAssignmentRepository
{
    public Task AssignCreativeToPlacementAsync(Guid creativeId, Guid placementId)
    {
        // Lógica de persistencia con Dapper/SQLite iría aquí
        return Task.CompletedTask;
    }

    public Task<IEnumerable<Guid>> GetCreativeIdsByPlacementAsync(Guid placementId)
    {
        // Lógica de persistencia con Dapper/SQLite iría aquí
        return Task.FromResult(Enumerable.Empty<Guid>());
    }
}