using System;
using System.Reflection;

namespace Abp.Dapper_Extensions.Mapper
{
    public class PropertyKey
    {
        public string Name { get; }
        public PropertyInfo PropertyInfo { get; }
        public Type EntityType { get; }

        public PropertyKey(PropertyInfo propertyInfo, Type entityType, string name)
        {
            Name = name;
            PropertyInfo = propertyInfo;
            EntityType = entityType;
        }
    }
}
