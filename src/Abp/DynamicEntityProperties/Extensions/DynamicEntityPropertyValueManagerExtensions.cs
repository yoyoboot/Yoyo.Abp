using System.Collections.Generic;
using System.Threading.Tasks;
using Abp.Domain.Entities;

namespace Abp.DynamicEntityProperties.Extensions
{
    public static class DynamicEntityPropertyValueManagerExtensions
    {
        public static List<DynamicEntityPropertyValue> GetValues<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValues(entityFullName: typeof(TEntity).FullName, entityId: entityId);
        }

        public static List<DynamicEntityPropertyValue> GetValues<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId)
            where TEntity : IEntity<string>
        {
            return manager.GetValues<TEntity, string>(entityId: entityId);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValuesAsync(entityFullName: typeof(TEntity).FullName, entityId: entityId);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId)
            where TEntity : IEntity<string>
        {
            return manager.GetValuesAsync<TEntity, string>(entityId: entityId);
        }

        public static List<DynamicEntityPropertyValue> GetValues<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string dynamicPropertyId)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValues(entityFullName: typeof(TEntity).FullName, entityId: entityId, dynamicPropertyId: dynamicPropertyId);
        }

        public static List<DynamicEntityPropertyValue> GetValues<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string dynamicPropertyId)
            where TEntity : IEntity<string>
        {
            return manager.GetValues<TEntity, string>(entityId: entityId, dynamicPropertyId: dynamicPropertyId);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string dynamicPropertyId)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValuesAsync(entityFullName: typeof(TEntity).FullName, entityId: entityId, dynamicPropertyId: dynamicPropertyId);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string dynamicPropertyId)
            where TEntity : IEntity<string>
        {
            return manager.GetValuesAsync<TEntity, string>(entityId: entityId, dynamicPropertyId: dynamicPropertyId);
        }

        public static List<DynamicEntityPropertyValue> GetValues<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, DynamicProperty dynamicProperty)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValues<TEntity, TPrimaryKey>(entityId: entityId, dynamicPropertyId: dynamicProperty.Id);
        }

        public static List<DynamicEntityPropertyValue> GetValues<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, DynamicProperty dynamicProperty)
            where TEntity : IEntity<string>
        {
            return manager.GetValues<TEntity>(entityId: entityId, dynamicPropertyId: dynamicProperty.Id);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, DynamicProperty dynamicProperty)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValuesAsync<TEntity, TPrimaryKey>(entityId: entityId, dynamicPropertyId: dynamicProperty.Id);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, DynamicProperty dynamicProperty)
            where TEntity : IEntity<string>
        {
            return manager.GetValuesAsync<TEntity>(entityId: entityId, dynamicPropertyId: dynamicProperty.Id);
        }

        public static List<DynamicEntityPropertyValue> GetValues<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValues(entityFullName: typeof(TEntity).FullName, entityId: entityId, propertyName: propertyName);
        }

        public static List<DynamicEntityPropertyValue> GetValues<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)
            where TEntity : IEntity<string>
        {
            return manager.GetValues<TEntity, string>(entityId: entityId, propertyName: propertyName);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)
            where TEntity : IEntity<TPrimaryKey>
        {
            return manager.GetValuesAsync(entityFullName: typeof(TEntity).FullName, entityId: entityId, propertyName: propertyName);
        }

        public static Task<List<DynamicEntityPropertyValue>> GetValuesAsync<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)
            where TEntity : IEntity<string>
        {
            return manager.GetValuesAsync<TEntity, string>(entityId: entityId, propertyName: propertyName);
        }
    }
}
