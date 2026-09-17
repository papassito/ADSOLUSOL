namespace ADSOLUSOL.Domain.Interfaces;

public interface IPlacementRepository
{
    // Métodos de ejemplo para la gestión de placements
    Task<Guid> CreatePlacementAsync(string name);
    Task<string?> GetPlacementNameAsync(Guid placementId);
}