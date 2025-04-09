using System.Threading.Tasks;

namespace Abp.MultiTenancy
{
    public interface ITenantCache
    {
        TenantCacheItem Get(string tenantId,int? fsTagNone=null);

        TenantCacheItem Get(string tenancyName);

        TenantCacheItem GetOrNull(string tenancyName);

        TenantCacheItem GetOrNull(string tenantId,int? fsTagNone=null);

        Task<TenantCacheItem> GetAsync(string tenantId,int? fsTagNone=null);

        Task<TenantCacheItem> GetAsync(string tenancyName);

        Task<TenantCacheItem> GetOrNullAsync(string tenancyName);

        Task<TenantCacheItem> GetOrNullAsync(string tenantId,int? fsTagNone=null);
    }
}
