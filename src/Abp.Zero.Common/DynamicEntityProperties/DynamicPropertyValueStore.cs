using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.Linq;

namespace Abp.DynamicEntityProperties
{
    public class DynamicPropertyValueStore : IDynamicPropertyValueStore, ITransientDependency
    {
        private readonly IRepository<DynamicPropertyValue, string> _dynamicPropertyValuesRepository;
        private readonly IAsyncQueryableExecuter _asyncQueryableExecuter;

        public DynamicPropertyValueStore(
            IRepository<DynamicPropertyValue, string> dynamicPropertyValuesRepository,
            IAsyncQueryableExecuter asyncQueryableExecuter)
        {
            _dynamicPropertyValuesRepository = dynamicPropertyValuesRepository;
            _asyncQueryableExecuter = asyncQueryableExecuter;
        }

        public virtual DynamicPropertyValue Get(string id)
        {
            return _dynamicPropertyValuesRepository.Get(id);
        }

        public virtual Task<DynamicPropertyValue> GetAsync(string id)
        {
            return _dynamicPropertyValuesRepository.GetAsync(id);
        }

        public virtual List<DynamicPropertyValue> GetAllValuesOfDynamicProperty(string dynamicPropertyId)
        {
            return _dynamicPropertyValuesRepository.GetAll()
                .Where(propertyValue => propertyValue.DynamicPropertyId == dynamicPropertyId).ToList();
        }

        public virtual Task<List<DynamicPropertyValue>> GetAllValuesOfDynamicPropertyAsync(string dynamicPropertyId)
        {
            return _asyncQueryableExecuter.ToListAsync(_dynamicPropertyValuesRepository.GetAll()
                .Where(propertyValue => propertyValue.DynamicPropertyId == dynamicPropertyId));
        }

        public virtual void Add(DynamicPropertyValue dynamicPropertyValue)
        {
            _dynamicPropertyValuesRepository.Insert(dynamicPropertyValue);
        }

        public virtual Task AddAsync(DynamicPropertyValue dynamicPropertyValue)
        {
            return _dynamicPropertyValuesRepository.InsertAsync(dynamicPropertyValue);
        }

        public virtual void Update(DynamicPropertyValue dynamicPropertyValue)
        {
            _dynamicPropertyValuesRepository.Update(dynamicPropertyValue);
        }

        public virtual Task UpdateAsync(DynamicPropertyValue dynamicPropertyValue)
        {
            return _dynamicPropertyValuesRepository.UpdateAsync(dynamicPropertyValue);
        }

        public virtual void Delete(string id)
        {
            _dynamicPropertyValuesRepository.Delete(id);
        }

        public virtual Task DeleteAsync(string id)
        {
            return _dynamicPropertyValuesRepository.DeleteAsync(id);
        }

        public virtual void CleanValues(string dynamicPropertyId)
        {
            _dynamicPropertyValuesRepository.Delete(value => value.DynamicPropertyId == dynamicPropertyId);
        }

        public virtual Task CleanValuesAsync(string dynamicPropertyId)
        {
            return _dynamicPropertyValuesRepository.DeleteAsync(value => value.DynamicPropertyId == dynamicPropertyId);
        }
    }
}
