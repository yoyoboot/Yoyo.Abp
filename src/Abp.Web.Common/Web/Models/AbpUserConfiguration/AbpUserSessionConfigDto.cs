using Abp.MultiTenancy;

namespace Abp.Web.Models.AbpUserConfiguration
{
    public class AbpUserSessionConfigDto
    {
        public string UserId { get; set; }

        public string TenantId { get; set; }

        public string ImpersonatorUserId { get; set; }

        public string ImpersonatorTenantId { get; set; }

        public MultiTenancySides MultiTenancySide { get; set; }
    }
}
