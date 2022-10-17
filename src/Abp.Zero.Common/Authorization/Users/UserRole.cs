using System.ComponentModel.DataAnnotations.Schema;
using Abp.Domain.Entities;
using Abp.Domain.Entities.Auditing;

namespace Abp.Authorization.Users
{
    /// <summary>
    /// Represents role record of a user. 
    /// </summary>
    [Table("AbpUserRoles")]
    public class UserRole : CreationAuditedEntity<string>, IMayHaveTenant
    {
        public virtual string TenantId { get; set; }

        /// <summary>
        /// User id.
        /// </summary>
        public virtual string UserId { get; set; }

        /// <summary>
        /// Role id.
        /// </summary>
        public virtual string RoleId { get; set; }

        /// <summary>
        /// Creates a new <see cref="UserRole"/> object.
        /// </summary>
        public UserRole()
        {

        }

        /// <summary>
        /// Creates a new <see cref="UserRole"/> object.
        /// </summary>
        /// <param name="tenantId">Tenant id</param>
        /// <param name="userId">User id</param>
        /// <param name="roleId">Role id</param>
        public UserRole(string tenantId, string userId, string roleId)
        {
            TenantId = tenantId;
            UserId = userId;
            RoleId = roleId;
        }
    }
}
