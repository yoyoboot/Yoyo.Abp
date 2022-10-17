namespace Abp.MultiTenancy
{
    public class TenantResolverCacheItem
    {
        public string TenantId { get; }

        public TenantResolverCacheItem(string tenantId)
        {
            TenantId = tenantId;
        }
    }
}
