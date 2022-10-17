using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Dependency;
using Abp.Domain.Entities;

namespace Abp.DynamicEntityProperties
{
    public class DynamicEntityPropertyValueManager : IDynamicEntityPropertyValueManager, ITransientDependency
    {
        private readonly IDynamicPropertyPermissionChecker _dynamicPropertyPermissionChecker;
        private readonly IDynamicPropertyManager _dynamicPropertyManager;
        private readonly IDynamicEntityPropertyManager _dynamicEntityPropertyManager;

        public IDynamicEntityPropertyValueStore DynamicEntityPropertyValueStore { get; set; }

        public DynamicEntityPropertyValueManager(
            IDynamicPropertyPermissionChecker dynamicPropertyPermissionChecker,
            IDynamicPropertyManager dynamicPropertyManager,
            IDynamicEntityPropertyManager dynamicEntityPropertyManager
        )
        {
            _dynamicPropertyPermissionChecker = dynamicPropertyPermissionChecker;
            _dynamicPropertyManager = dynamicPropertyManager;
            _dynamicEntityPropertyManager = dynamicEntityPropertyManager;
            DynamicEntityPropertyValueStore = NullDynamicEntityPropertyValueStore.Instance;
        }

        private string GetDynamicPropertyId(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            if (dynamicEntityPropertyValue.DynamicEntityPropertyId == default)
            {
                throw new ArgumentNullException(nameof(dynamicEntityPropertyValue.DynamicEntityPropertyId));
            }

            if (dynamicEntityPropertyValue.DynamicEntityProperty != null)
            {
                return dynamicEntityPropertyValue.DynamicEntityProperty.DynamicPropertyId;
            }

            var dynamicEntityProperty =
                _dynamicEntityPropertyManager.Get(dynamicEntityPropertyValue.DynamicEntityPropertyId);

            return _dynamicPropertyManager.Get(dynamicEntityProperty.DynamicPropertyId).Id;
        }

        private async Task<string> GetDynamicPropertyIdAsync(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            if (dynamicEntityPropertyValue.DynamicEntityPropertyId == default)
            {
                throw new ArgumentNullException(nameof(dynamicEntityPropertyValue.DynamicEntityPropertyId));
            }

            if (dynamicEntityPropertyValue.DynamicEntityProperty != null)
            {
                return dynamicEntityPropertyValue.DynamicEntityProperty.DynamicPropertyId;
            }

            var dynamicEntityProperty =
                await _dynamicEntityPropertyManager.GetAsync(dynamicEntityPropertyValue.DynamicEntityPropertyId);

            return (await _dynamicPropertyManager.GetAsync(dynamicEntityProperty.DynamicPropertyId)).Id;
        }

        public virtual DynamicEntityPropertyValue Get(string id)
        {
            var value = DynamicEntityPropertyValueStore.Get(id);
            _dynamicPropertyPermissionChecker.CheckPermission(GetDynamicPropertyId(value));
            return value;
        }

        public virtual async Task<DynamicEntityPropertyValue> GetAsync(string id)
        {
            var value = await DynamicEntityPropertyValueStore.GetAsync(id);
            await _dynamicPropertyPermissionChecker.CheckPermissionAsync(await GetDynamicPropertyIdAsync(value));
            return value;
        }

        public virtual void Add(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            _dynamicPropertyPermissionChecker.CheckPermission(GetDynamicPropertyId(dynamicEntityPropertyValue));
            DynamicEntityPropertyValueStore.Add(dynamicEntityPropertyValue);
        }

        public virtual async Task AddAsync(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            await _dynamicPropertyPermissionChecker.CheckPermissionAsync(
                await GetDynamicPropertyIdAsync(dynamicEntityPropertyValue));
            await DynamicEntityPropertyValueStore.AddAsync(dynamicEntityPropertyValue);
        }

        public virtual void Update(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            _dynamicPropertyPermissionChecker.CheckPermission(GetDynamicPropertyId(dynamicEntityPropertyValue));
            DynamicEntityPropertyValueStore.Update(dynamicEntityPropertyValue);
        }

        public virtual async Task UpdateAsync(DynamicEntityPropertyValue dynamicEntityPropertyValue)
        {
            await _dynamicPropertyPermissionChecker.CheckPermissionAsync(
                await GetDynamicPropertyIdAsync(dynamicEntityPropertyValue));
            await DynamicEntityPropertyValueStore.UpdateAsync(dynamicEntityPropertyValue);
        }

        public virtual void Delete(string id)
        {
            var dynamicEntityPropertyValue = Get(id); //Get checks permission, no need to check it again
            if (dynamicEntityPropertyValue == null)
            {
                return;
            }

            DynamicEntityPropertyValueStore.Delete(id);
        }

        public virtual async Task DeleteAsync(string id)
        {
            var dynamicEntityPropertyValue = await GetAsync(id); //Get checks permission, no need to check it again
            if (dynamicEntityPropertyValue == null)
            {
                return;
            }

            await DynamicEntityPropertyValueStore.DeleteAsync(id);
        }

        public List<DynamicEntityPropertyValue> GetValues(string dynamicEntityPropertyId, string entityId)
        {
            var dynamicEntityProperty = _dynamicEntityPropertyManager.Get(dynamicEntityPropertyId);
            _dynamicPropertyPermissionChecker.CheckPermission(dynamicEntityProperty.DynamicPropertyId);

            return DynamicEntityPropertyValueStore.GetValues(dynamicEntityPropertyId, entityId);
        }

        public async Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string dynamicEntityPropertyId, string entityId)
        {
            var dynamicEntityProperty = await _dynamicEntityPropertyManager.GetAsync(dynamicEntityPropertyId);
            await _dynamicPropertyPermissionChecker.CheckPermissionAsync(dynamicEntityProperty.DynamicPropertyId);

            return await DynamicEntityPropertyValueStore.GetValuesAsync(dynamicEntityPropertyId, entityId);
        }

        public List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId,int? fsTagNone=null)
        {
            return DynamicEntityPropertyValueStore.GetValues(entityFullName, entityId)
                .Where(value =>
                {
                    var dynamicEntityProperty = _dynamicEntityPropertyManager.Get(value.DynamicEntityPropertyId);
                    return _dynamicPropertyPermissionChecker.IsGranted(dynamicEntityProperty.DynamicPropertyId);
                })
                .ToList();
        }

        public async Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId,int? fsTagNone=null)
        {
            var allValues = await DynamicEntityPropertyValueStore.GetValuesAsync(entityFullName, entityId);
            var returnList = new List<DynamicEntityPropertyValue>();

            foreach (var value in allValues)
            {
                var dynamicEntityProperty = await _dynamicEntityPropertyManager.GetAsync(value.DynamicEntityPropertyId);

                if (await _dynamicPropertyPermissionChecker.IsGrantedAsync(dynamicEntityProperty.DynamicPropertyId))
                {
                    returnList.Add(value);
                }
            }

            return returnList;
        }

        public List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId, string dynamicPropertyId)
        {
            return DynamicEntityPropertyValueStore.GetValues(entityFullName, entityId, dynamicPropertyId)
                .Where(value =>
                {
                    var dynamicEntityProperty = _dynamicEntityPropertyManager.Get(value.DynamicEntityPropertyId);
                    return _dynamicPropertyPermissionChecker.IsGranted(dynamicEntityProperty.DynamicPropertyId);
                })
                .ToList();
        }

        public async Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId,
            string dynamicPropertyId)
        {
            var allValues =
                await DynamicEntityPropertyValueStore.GetValuesAsync(entityFullName, entityId, dynamicPropertyId);
            var returnList = new List<DynamicEntityPropertyValue>();

            foreach (var value in allValues)
            {
                var dynamicEntityProperty = await _dynamicEntityPropertyManager.GetAsync(value.DynamicEntityPropertyId);

                if (await _dynamicPropertyPermissionChecker.IsGrantedAsync(dynamicEntityProperty.DynamicPropertyId))
                {
                    returnList.Add(value);
                }
            }

            return returnList;
        }

        public List<DynamicEntityPropertyValue> GetValues(string entityFullName, string entityId, string propertyName,int? fsTagNone=null)
        {
            var dynamicProperty = _dynamicPropertyManager.Get(propertyName);
            if (dynamicProperty == null)
            {
                throw new EntityNotFoundException($"There is no DynamicProperty with propertyName: \"{propertyName}\"");
            }

            return GetValues(entityFullName, entityId, dynamicProperty.Id);
        }

        public async Task<List<DynamicEntityPropertyValue>> GetValuesAsync(string entityFullName, string entityId,
             string propertyName,int? fsTagNone=null)
        {
            var dynamicProperty = await _dynamicPropertyManager.GetAsync(propertyName);
            if (dynamicProperty == null)
            {
                throw new EntityNotFoundException($"There is no DynamicProperty with propertyName: \"{propertyName}\"");
            }

            return await GetValuesAsync(entityFullName, entityId, dynamicProperty.Id);
        }

        public void CleanValues(string dynamicEntityPropertyId, string entityId)
        {
            var dynamicEntityProperty = _dynamicEntityPropertyManager.Get(dynamicEntityPropertyId);
            _dynamicPropertyPermissionChecker.CheckPermission(dynamicEntityProperty.DynamicPropertyId);

            DynamicEntityPropertyValueStore.CleanValues(dynamicEntityPropertyId, entityId);
        }

        public async Task CleanValuesAsync(string dynamicEntityPropertyId, string entityId)
        {
            var dynamicEntityProperty = await _dynamicEntityPropertyManager.GetAsync(dynamicEntityPropertyId);
            await _dynamicPropertyPermissionChecker.CheckPermissionAsync(dynamicEntityProperty.DynamicPropertyId);

            await DynamicEntityPropertyValueStore.CleanValuesAsync(dynamicEntityPropertyId, entityId);
        }
    }
}
