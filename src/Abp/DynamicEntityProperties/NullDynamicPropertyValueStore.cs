using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public class NullDynamicPropertyValueStore : IDynamicPropertyValueStore
    {
        public static NullDynamicPropertyValueStore Instance = new NullDynamicPropertyValueStore();

        public DynamicPropertyValue Get(string id)
        {
            return default;
        }

        public Task<DynamicPropertyValue> GetAsync(string id)
        {
            return Task.FromResult<DynamicPropertyValue>(default);
        }

        public List<DynamicPropertyValue> GetAllValuesOfDynamicProperty(string dynamicPropertyId)
        {
            return new List<DynamicPropertyValue>();
        }

        public Task<List<DynamicPropertyValue>> GetAllValuesOfDynamicPropertyAsync(string dynamicPropertyId)
        {
            return Task.FromResult(new List<DynamicPropertyValue>());
        }

        public void Add(DynamicPropertyValue dynamicPropertyValue)
        {
        }

        public Task AddAsync(DynamicPropertyValue dynamicPropertyValue)
        {
            return Task.CompletedTask;
        }

        public void Update(DynamicPropertyValue dynamicPropertyValue)
        {
        }

        public Task UpdateAsync(DynamicPropertyValue dynamicPropertyValue)
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

        public void CleanValues(string dynamicPropertyId)
        {
        }

        public Task CleanValuesAsync(string dynamicPropertyId)
        {
            return Task.CompletedTask;
        }
    }
}
