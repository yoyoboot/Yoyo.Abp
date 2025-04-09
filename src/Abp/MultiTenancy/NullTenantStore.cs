namespace Abp.MultiTenancy
{
    public class NullTenantStore : ITenantStore
    {
        public TenantInfo FindById(string tenantId)
        {
            return null;
        }

        public TenantInfo Find(string tenancyName)
        {
            return null;
        }
    }
}
