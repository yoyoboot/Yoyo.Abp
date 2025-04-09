using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.DynamicEntityProperties
{
    public interface IDynamicPropertyStore
    {
        DynamicProperty Get(string id,int? fsTagNone=null);

        Task<DynamicProperty> GetAsync(string id,int? fsTagNone=null);

        DynamicProperty Get(string propertyName);

        Task<DynamicProperty> GetAsync(string propertyName);

        List<DynamicProperty> GetAll();

        Task<List<DynamicProperty>> GetAllAsync();

        void Add(DynamicProperty dynamicProperty);

        Task AddAsync(DynamicProperty dynamicProperty);

        void Update(DynamicProperty dynamicProperty);

        Task UpdateAsync(DynamicProperty dynamicProperty);

        void Delete(string id);

        Task DeleteAsync(string id);
    }
}
