using System;
using System.Security.Claims;
using Abp.Runtime.Security;

namespace Abp.Authorization
{
    internal static class AbpZeroClaimsIdentityHelper
    {
        public static string GetTenantId(ClaimsPrincipal principal)
        {
            var tenantIdOrNull = principal?.FindFirstValue(AbpClaimTypes.TenantId);
            if (tenantIdOrNull == null)
            {
                return null;
            }

            return tenantIdOrNull;
        }
    }
}
