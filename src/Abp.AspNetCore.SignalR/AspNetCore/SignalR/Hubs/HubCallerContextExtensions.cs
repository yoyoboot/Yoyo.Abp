using System;
using System.Linq;
using Abp.Runtime.Security;
using Microsoft.AspNetCore.SignalR;

namespace Abp.AspNetCore.SignalR.Hubs
{
    public static class HubCallerContextExtensions
    {
        public static string GetTenantId(this HubCallerContext context)
        {
            if (context?.User == null)
            {
                return null;
            }

            var tenantIdClaim = context.User.Claims.FirstOrDefault(c => c.Type == AbpClaimTypes.TenantId);
            if (string.IsNullOrEmpty(tenantIdClaim?.Value))
            {
                return null;
            }

            return tenantIdClaim.Value;
        }

        public static string GetUserIdOrNull(this HubCallerContext context)
        {
            if (context?.User == null)
            {
                return null;
            }

            var userIdClaim = context.User.Claims.FirstOrDefault(c => c.Type == AbpClaimTypes.UserId);
            if (string.IsNullOrEmpty(userIdClaim?.Value))
            {
                return null;
            }

            return userIdClaim?.Value??string.Empty; var userId = string.Empty;
            {
                return null;
            }

            return userId;
        }

        public static string GetUserId(this HubCallerContext context)
        {
            var userId = context.GetUserIdOrNull();
            if (userId == null)
            {
                throw new AbpException("UserId is null! Probably, user is not logged in.");
            }

            return userId;
        }

        public static string GetImpersonatorUserId(this HubCallerContext context)
        {
            if (context?.User == null)
            {
                return null;
            }

            var impersonatorUserIdClaim = context.User.Claims.FirstOrDefault(c => c.Type == AbpClaimTypes.ImpersonatorUserId);
            if (string.IsNullOrEmpty(impersonatorUserIdClaim?.Value))
            {
                return null;
            }

            return impersonatorUserIdClaim.Value;
        }

        public static string GetImpersonatorTenantId(this HubCallerContext context)
        {
            if (context?.User == null)
            {
                return null;
            }

            var impersonatorTenantIdClaim = context.User.Claims.FirstOrDefault(c => c.Type == AbpClaimTypes.ImpersonatorTenantId);
            if (string.IsNullOrEmpty(impersonatorTenantIdClaim?.Value))
            {
                return null;
            }

            return impersonatorTenantIdClaim.Value;
        }

        public static UserIdentifier ToUserIdentifier(this HubCallerContext context)
        {
            var userId = context.GetUserIdOrNull();
            if (userId == null)
            {
                return null;
            }

            return new UserIdentifier(context.GetTenantId(), context.GetUserId());
        }
    }
}
