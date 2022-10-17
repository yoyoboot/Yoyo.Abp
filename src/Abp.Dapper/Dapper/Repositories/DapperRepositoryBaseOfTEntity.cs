using Abp.Data;
using Abp.Domain.Entities;

namespace Abp.Dapper.Repositories
{
    public class DapperRepositoryBase<TEntity> : DapperRepositoryBase<TEntity, string>, IDapperRepository<TEntity>
        where TEntity : class, IEntity<string>
    {
        public DapperRepositoryBase(IActiveTransactionProvider activeTransactionProvider) : base(activeTransactionProvider)
        {
        }
    }
}
