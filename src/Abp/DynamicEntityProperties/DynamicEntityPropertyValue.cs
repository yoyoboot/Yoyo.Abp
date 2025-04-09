using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Abp.Domain.Entities;

namespace Abp.DynamicEntityProperties
{
    [Table("AbpDynamicEntityPropertyValues")]
    public class DynamicEntityPropertyValue : Entity<string>, IMayHaveTenant
    {
        [Required(AllowEmptyStrings = false)]
        public string Value { get; set; }

        public string EntityId { get; set; }

        public string DynamicEntityPropertyId { get; set; }

        public virtual DynamicEntityProperty DynamicEntityProperty { get; set; }

        public string TenantId { get; set; }

        public DynamicEntityPropertyValue()
        {

        }

        public DynamicEntityPropertyValue(DynamicEntityProperty dynamicEntityProperty, string entityId, string value, string tenantId)
        {
            DynamicEntityPropertyId = dynamicEntityProperty.Id;
            EntityId = entityId;
            Value = value;
            TenantId = tenantId;
        }
    }
}
