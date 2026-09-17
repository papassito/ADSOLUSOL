namespace ADSOLUSOL.Domain.Interfaces;

public interface ICreativeRepository
{
    // Métodos de ejemplo para la gestión de creatividades
    Task<Guid> CreateCreativeAsync(string content);
    Task<string?> GetCreativeContentAsync(Guid creativeId);
}