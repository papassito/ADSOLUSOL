namespace ADSOLUSOL.Domain.Interfaces;

public interface IAssignmentRepository
{
    // Métodos de ejemplo para la gestión de asignaciones
    Task AssignCreativeToPlacementAsync(Guid creativeId, Guid placementId);
    Task<IEnumerable<Guid>> GetCreativeIdsByPlacementAsync(Guid placementId);
}