using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public class NullDynamicEntityPropertyValueStore : IDynamicEntityPropertyValueStore
    {
        public static NullDynamicEntityPropertyValueStore Instance = new NullDynamicEntityPropertyValueStore();

        public DynamicEntityPropertyValue Get(string id)
        {
            return default;
        }

        public Task<DynamicEntityPropertyValue> GetAsync(string id)
        {
            return Task.FromResult<DynamicEntityPropertyValue>(default);
        }

        public void Add(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
        }

        public Task AddAsync(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            return Task.CompletedTask;
        }

        public void Update(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
        }

        public Task UpdateAsync(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            return Task.CompletedTask;
        }

        public void Delete(string id)
        {
        }

        public Task DeleteAsync(string id)
        {
            return Task.CompletedTask;
        }

        public List<DynamicEntityPropertyValue> GetValues(string dynamicEntityPropertyId, string entityId)
        {
            return new List<DynamicEntityPropertyValue>();
        }

        public Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string dynamicEntityPropertyId, string entityId)
        {
            return Task.FromResult(new List<DynamicEntityPropertyValue>());
        }

        public List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId,int? fsTagNone=null)
        {
            return new List<DynamicEntityPropertyValue>();
        }

        public Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId,int? fsTagNone=null)
        {
            return Task.FromResult(new List<DynamicEntityPropertyValue>());
        }

        public List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId, string dynamicPropertyId)
        {
            return new List<DynamicEntityPropertyValue>();
        }

        public Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId, string dynamicPropertyId)
        {
            return Task.FromResult(new List<DynamicEntityPropertyValue>());
        }

        public void CleanValues(string dynamicEntityPropertyId, string entityId)
        {
        }

        public Task CleanValuesAsync(string dynamicEntityPropertyId, string entityId)
        {
            return Task.CompletedTask;
        }
    }
}
