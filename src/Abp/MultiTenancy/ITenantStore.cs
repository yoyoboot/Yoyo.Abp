using JetBrains.Annotations;

namespace Abp.MultiTenancy
{
    public interface ITenantStore
    {
        [CanBeNull]
        TenantInfo FindById(string tenantId);

        [CanBeNull]
        TenantInfo Find([NotNull] string tenancyName);
    }
}
