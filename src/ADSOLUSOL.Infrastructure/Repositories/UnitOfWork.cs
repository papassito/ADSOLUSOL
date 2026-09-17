using ADSOLUSOL.Domain.Interfaces;
using ADSOLUSOL.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using System.Data;

namespace ADSOLUSOL.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;
    private IDbContextTransaction? _efTransaction;

    public UnitOfWork(AppDbContext context)
    {
        _context = context;
    }

    public IDbTransaction? Transaction => _efTransaction?.GetDbTransaction();

    public async Task<IDbTransaction> BeginTransactionAsync()
    {
        _efTransaction = await _context.Database.BeginTransactionAsync();
        return _efTransaction.GetDbTransaction();
    }

    public async Task CommitAsync()
    {
        if (_efTransaction != null)
        {
            await _efTransaction.CommitAsync();
            await _efTransaction.DisposeAsync();
            _efTransaction = null;
        }
    }

    public async Task RollbackAsync()
    {
        if (_efTransaction != null)
        {
            await _efTransaction.RollbackAsync();
            await _efTransaction.DisposeAsync();
            _efTransaction = null;
        }
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public void Dispose()
    {
        _efTransaction?.Dispose();
        _context.Dispose();
    }
}