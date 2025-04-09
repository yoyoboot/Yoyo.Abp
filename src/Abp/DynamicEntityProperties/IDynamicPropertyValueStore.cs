using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public interface IDynamicPropertyValueStore
    {
        DynamicPropertyValue Get(string id);

        Task<DynamicPropertyValue> GetAsync(string id);

        List<DynamicPropertyValue> GetAllValuesOfDynamicProperty(string dynamicPropertyId);

        Task<List<DynamicPropertyValue>> GetAllValuesOfDynamicPropertyAsync(string dynamicPropertyId);

        void Add(DynamicPropertyValue dynamicPropertyValue);

        Task AddAsync(DynamicPropertyValue dynamicPropertyValue);

        void Update(DynamicPropertyValue dynamicPropertyValue);

        Task UpdateAsync(DynamicPropertyValue dynamicPropertyValue);

        void Delete(string id);

        Task DeleteAsync(string id);

        void CleanValues(string dynamicPropertyId);

        Task CleanValuesAsync(string dynamicPropertyId);
    }
}
