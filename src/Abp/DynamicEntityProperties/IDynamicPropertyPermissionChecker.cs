using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public interface IDynamicPropertyPermissionChecker
    {
        void CheckPermission(string dynamicPropertyId);

        Task CheckPermissionAsync(string dynamicPropertyId);

        bool IsGranted(string dynamicPropertyId);

        Task<bool> IsGrantedAsync(string dynamicPropertyId);
    }
}
