using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public interface IDynamicEntityPropertyValueManager
    {
        DynamicEntityPropertyValue Get(string id);

        Task<DynamicEntityPropertyValue> GetAsync(string id);

        void Add(DynamicEntityPropertyValue dynamicEntityPropertyValue);

        Task AddAsync(DynamicEntityPropertyValue dynamicEntityPropertyValue);

        void Update(DynamicEntityPropertyValue dynamicEntityPropertyValue);

        Task UpdateAsync(DynamicEntityPropertyValue dynamicEntityPropertyValue);

        void Delete(string id);

        Task DeleteAsync(string id);

        List<DynamicEntityPropertyValue> GetValues(string dynamicEntityPropertyId, string entityId);

        Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string dynamicEntityPropertyId, string entityId);

        List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId,int? fsTagNone=null);

        Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId,int? fsTagNone=null);

        List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId, string dynamicPropertyId);

        Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId, string dynamicPropertyId);

        List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId, string propertyName,int? fsTagNone=null);

        Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId, string propertyName,int? fsTagNone=null);

        void CleanValues(string dynamicEntityPropertyId, string entityId);

        Task CleanValuesAsync(string dynamicEntityPropertyId, string entityId);
    }
}
