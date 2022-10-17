using System.Threading.Tasks;

namespace Abp.MultiTenancy
{
    public interface ITenantResolver
    {
        string ResolveTenantId();
        
        Task<string> ResolveTenantIdAsync();
    }
}
