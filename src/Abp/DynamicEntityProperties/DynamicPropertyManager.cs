using System;
using System.Threading.Tasks;
using System.Transactions;
using Abp.Dependency;
using Abp.Domain.Uow;
using Abp.Extensions;
using Abp.Runtime.Caching;

namespace Abp.DynamicEntityProperties
{
    public class DynamicPropertyManager : IDynamicPropertyManager, ITransientDependency
    {
        private readonly ICacheManager _cacheManager;
        private readonly IDynamicPropertyStore _dynamicPropertyStore;
        private readonly IUnitOfWorkManager _unitOfWorkManager;
        private readonly IDynamicEntityPropertyDefinitionManager _dynamicEntityPropertyDefinitionManager;

        public const string CacheName = "AbpZeroDynamicPropertyCache";
        private ITypedCache<string, DynamicProperty> DynamicPropertyCache => _cacheManager.GetCache<string, DynamicProperty>(CacheName);

        public DynamicPropertyManager(
            ICacheManager cacheManager,
            IDynamicPropertyStore dynamicPropertyStore,
            IUnitOfWorkManager unitOfWorkManager,
            IDynamicEntityPropertyDefinitionManager dynamicEntityPropertyDefinitionManager
        )
        {
            _cacheManager = cacheManager;
            _dynamicPropertyStore = dynamicPropertyStore;
            _unitOfWorkManager = unitOfWorkManager;
            _dynamicEntityPropertyDefinitionManager = dynamicEntityPropertyDefinitionManager;
        }

        public virtual DynamicProperty Get(string id,int? fsTagNone=null)
        {
            return DynamicPropertyCache.Get(id, () => _dynamicPropertyStore.Get(id));
        }

        public virtual Task<DynamicProperty> GetAsync(string id,int? fsTagNone=null)
        {
            return DynamicPropertyCache.GetAsync(id, (i) => _dynamicPropertyStore.GetAsync(id));
        }

        public virtual DynamicProperty Get(string propertyName)
        {
            return _dynamicPropertyStore.Get(propertyName);
        }

        public virtual Task<DynamicProperty> GetAsync(string propertyName)
        {
            return _dynamicPropertyStore.GetAsync(propertyName);
        }

        protected virtual void CheckDynamicProperty(DynamicProperty dynamicProperty)
        {
            if (dynamicProperty == null)
            {
                throw new ArgumentNullException(nameof(dynamicProperty));
            }

            if (dynamicProperty.PropertyName.IsNullOrWhiteSpace())
            {
                throw new ArgumentNullException(nameof(dynamicProperty.PropertyName));
            }

            if (!_dynamicEntityPropertyDefinitionManager.ContainsInputType(dynamicProperty.InputType))
            {
                throw new ApplicationException($"Input type is invalid, if you want to use \"{dynamicProperty.InputType}\" input type, define it in DynamicEntityPropertyDefinitionProvider.");
            }
        }

        public virtual DynamicProperty Add(DynamicProperty dynamicProperty)
        {
            CheckDynamicProperty(dynamicProperty);

            using (var uow = _unitOfWorkManager.Begin(TransactionScopeOption.RequiresNew))
            {
                _dynamicPropertyStore.Add(dynamicProperty);
                uow.Complete();
            }

            DynamicPropertyCache.Set(dynamicProperty.Id, dynamicProperty);

            return dynamicProperty;
        }

        public virtual async Task<DynamicProperty> AddAsync(DynamicProperty dynamicProperty)
        {
            CheckDynamicProperty(dynamicProperty);

            using (var uow = _unitOfWorkManager.Begin(TransactionScopeOption.RequiresNew))
            {
                await _dynamicPropertyStore.AddAsync(dynamicProperty);
                await uow.CompleteAsync();
            }

            await DynamicPropertyCache.SetAsync(dynamicProperty.Id, dynamicProperty);
            
            return dynamicProperty;
        }

        public virtual DynamicProperty Update(DynamicProperty dynamicProperty)
        {
            CheckDynamicProperty(dynamicProperty);

            using (var uow = _unitOfWorkManager.Begin(TransactionScopeOption.RequiresNew))
            {
                _dynamicPropertyStore.Update(dynamicProperty);
                uow.Complete();
            }

            DynamicPropertyCache.Set(dynamicProperty.Id, dynamicProperty);
            
            return dynamicProperty;
        }

        public virtual async Task<DynamicProperty> UpdateAsync(DynamicProperty dynamicProperty)
        {
            CheckDynamicProperty(dynamicProperty);

            using (var uow = _unitOfWorkManager.Begin(TransactionScopeOption.RequiresNew))
            {
                await _dynamicPropertyStore.UpdateAsync(dynamicProperty);
                await uow.CompleteAsync();
            }

            await DynamicPropertyCache.SetAsync(dynamicProperty.Id, dynamicProperty);
            
            return dynamicProperty;
        }

        public virtual void Delete(string id)
        {
            using (var uow = _unitOfWorkManager.Begin(TransactionScopeOption.RequiresNew))
            {
                _dynamicPropertyStore.Delete(id);
                uow.Complete();
            }

            DynamicPropertyCache.Remove(id);
        }

        public virtual async Task DeleteAsync(string id)
        {
            using (var uow = _unitOfWorkManager.Begin(TransactionScopeOption.RequiresNew))
            {
                await _dynamicPropertyStore.DeleteAsync(id);
                await uow.CompleteAsync();
            }

            await DynamicPropertyCache.RemoveAsync(id);
        }
    }
}
