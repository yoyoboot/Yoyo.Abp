using Abp.Runtime.Caching;

namespace Abp.MultiTenancy
{
    public static class TenantCacheManagerExtensions
    {
        public static ITypedCache<string, TenantCacheItem> GetTenantCache(this ICacheManager cacheManager)
        {
            return cacheManager.GetCache<string, TenantCacheItem>(TenantCacheItem.CacheName);
        }

        public static ITypedCache<string, string> GetTenantByNameCache(this ICacheManager cacheManager)
        {
            return cacheManager.GetCache<string, string>(TenantCacheItem.ByNameCacheName);
        }
    }
}
