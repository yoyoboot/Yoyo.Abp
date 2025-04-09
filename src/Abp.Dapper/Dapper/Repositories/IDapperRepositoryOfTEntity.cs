using Abp.Domain.Entities;

namespace Abp.Dapper.Repositories
{
    public interface IDapperRepository<TEntity> : IDapperRepository<TEntity, string> where TEntity : class, IEntity<string>
    {
    }
}
