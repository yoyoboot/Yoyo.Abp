using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public class NullDynamicPropertyStore : IDynamicPropertyStore
    {
        public static NullDynamicPropertyStore Instance = new NullDynamicPropertyStore();

        public DynamicProperty Get(string id,int? fsTagNone=null)
        {
            return default;
        }

        public Task<DynamicProperty> GetAsync(string id,int? fsTagNone=null)
        {
            return Task.FromResult<DynamicProperty>(default);
        }

        public DynamicProperty Get(string propertyName)
        {
            return default;
        }

        public Task<DynamicProperty> GetAsync(string propertyName)
        {
            return Task.FromResult<DynamicProperty>(default);
        }

        public List<DynamicProperty> GetAll()
        {
            return new List<DynamicProperty>();
        }

        public Task<List<DynamicProperty>> GetAllAsync()
        {
            return Task.FromResult(new List<DynamicProperty>());
        }

        public void Add(DynamicProperty dynamicProperty)
        {
        }

        public Task AddAsync(DynamicProperty dynamicProperty)
        {
            return Task.CompletedTask;
        }

        public void Update(DynamicProperty dynamicProperty)
        {
        }

        public Task UpdateAsync(DynamicProperty dynamicProperty)
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
    }
}
