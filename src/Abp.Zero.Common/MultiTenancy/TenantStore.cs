namespace Abp.MultiTenancy
{
    public class TenantStore : ITenantStore
    {
        private readonly ITenantCache _tenantCache;

        public TenantStore(ITenantCache tenantCache)
        {
            _tenantCache = tenantCache;
        }

        public TenantInfo FindById(string tenantId)
        {
            var tenant = _tenantCache.GetOrNull(tenantId, null);
            if (tenant == null)
            {
                return null;
            }

            return new TenantInfo(tenant.Id, tenant.TenancyName);
        }

        public TenantInfo Find(string tenancyName)
        {
            var tenant = _tenantCache.GetOrNull(tenancyName);
            if (tenant == null)
            {
                return null;
            }

            return new TenantInfo(tenant.Id, tenant.TenancyName);
        }
    }
}
