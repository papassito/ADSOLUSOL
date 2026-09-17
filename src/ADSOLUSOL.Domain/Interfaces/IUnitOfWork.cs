using System.Data;

namespace ADSOLUSOL.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IDbTransaction? Transaction { get; }
    Task<IDbTransaction> BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
