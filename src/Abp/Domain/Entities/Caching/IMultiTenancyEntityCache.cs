using Abp.Runtime.Caching;

namespace Abp.Domain.Entities.Caching
{
    public interface IMultiTenancyEntityCache<TCacheItem> : IMultiTenancyEntityCache<TCacheItem, string>
    {
    }

    public interface IMultiTenancyEntityCache<TCacheItem, TPrimaryKey> : IEntityCacheBase<TCacheItem, TPrimaryKey>
    {
        ITypedCache<string, TCacheItem> InternalCache { get; }

        string GetCacheKey(TPrimaryKey id);

        string GetCacheKey(TPrimaryKey id, string tenantId);
    }
}
