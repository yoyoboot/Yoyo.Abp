using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Abp.Domain.Entities;
using Abp.Domain.Entities.Auditing;

namespace Abp.Configuration
{
    /// <summary>
    /// Represents a setting for a tenant or user.
    /// </summary>
    [Table("AbpSettings")]
    public class Setting : AuditedEntity<string>, IMayHaveTenant
    {
        /// <summary>
        /// Maximum length of the <see cref="Name"/> property.
        /// </summary>
        public const int MaxNameLength = 256;
     
        /// <summary>
        /// TenantId for this setting.
        /// TenantId is null if this setting is not Tenant level.
        /// </summary>
        public virtual string TenantId { get; set; }

        /// <summary>
        /// UserId for this setting.
        /// UserId is null if this setting is not user level.
        /// </summary>
        public virtual string UserId { get; set; }

        /// <summary>
        /// Unique name of the setting.
        /// </summary>
        [Required]
        [StringLength(MaxNameLength)]
        public virtual string Name { get; set; }

        /// <summary>
        /// Value of the setting.
        /// </summary>
        public virtual string Value { get; set; }

        /// <summary>
        /// Creates a new <see cref="Setting"/> object.
        /// </summary>
        public Setting()
        {

        }

        /// <summary>
        /// Creates a new <see cref="Setting"/> object.
        /// </summary>
        /// <param name="tenantId">TenantId for this setting</param>
        /// <param name="userId">UserId for this setting</param>
        /// <param name="name">Unique name of the setting</param>
        /// <param name="value">Value of the setting</param>
        public Setting(string tenantId, string userId, string name, string value)
        {
            TenantId = tenantId;
            UserId = userId;
            Name = name;
            Value = value;
        }
    }
}
