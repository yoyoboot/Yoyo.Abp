using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public interface IDynamicPropertyManager
    {
        DynamicProperty Get(string id,int? fsTagNone=null);

        Task<DynamicProperty> GetAsync(string id,int? fsTagNone=null);

        DynamicProperty Get(string propertyName);

        Task<DynamicProperty> GetAsync(string propertyName);

        DynamicProperty Add(DynamicProperty dynamicProperty);

        Task<DynamicProperty> AddAsync(DynamicProperty dynamicProperty);

        DynamicProperty Update(DynamicProperty dynamicProperty);

        Task<DynamicProperty> UpdateAsync(DynamicProperty dynamicProperty);

        void Delete(string id);

        Task DeleteAsync(string id);
    }
}
