namespace Abp.MultiTenancy
{
    public class TenantInfo
    {
        public string Id { get; set; }

        public string TenancyName { get; set; }

        public TenantInfo(string id, string tenancyName)
        {
            Id = id;
            TenancyName = tenancyName;
        }
    }
}
