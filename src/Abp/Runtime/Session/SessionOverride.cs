namespace Abp.Runtime.Session
{
    public class SessionOverride
    {
        public string UserId { get; }

        public string TenantId { get; }

        public SessionOverride(string tenantId, string userId)
        {
            TenantId = tenantId;
            UserId = userId;
        }
    }
}
