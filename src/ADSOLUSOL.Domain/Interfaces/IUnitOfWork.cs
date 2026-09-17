using System.Data;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IUnitOfWork
{
    IDbTransaction? Transaction { get; }
    Task BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
