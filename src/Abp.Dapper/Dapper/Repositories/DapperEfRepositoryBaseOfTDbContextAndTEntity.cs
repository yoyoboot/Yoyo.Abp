using Abp.Data;
using Abp.Domain.Entities;
using Abp.Domain.Uow;
using Abp.Transactions;

namespace Abp.Dapper.Repositories
{
    public class DapperEfRepositoryBase<TDbContext, TEntity> : DapperEfRepositoryBase<TDbContext, TEntity, string>, IDapperRepository<TEntity>
        where TEntity : class, IEntity<string>
        where TDbContext : class

    {
        public DapperEfRepositoryBase(IActiveTransactionProvider activeTransactionProvider,
            ICurrentUnitOfWorkProvider currentUnitOfWorkProvider)
            : base(activeTransactionProvider, currentUnitOfWorkProvider)
        {
        }
    }
}
