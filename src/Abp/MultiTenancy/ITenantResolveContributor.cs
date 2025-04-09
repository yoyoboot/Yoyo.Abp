namespace Abp.MultiTenancy
{
    public interface ITenantResolveContributor
    {
        string ResolveTenantId();
    }
}
