using System.ComponentModel.DataAnnotations.Schema;
using Abp.Domain.Entities;
using Abp.Domain.Entities.Auditing;

namespace Abp.Organizations
{
    /// <summary>
    /// Represents membership of a User to an OU.
    /// </summary>
    [Table("AbpOrganizationUnitRoles")]
    public class OrganizationUnitRole : CreationAuditedEntity<string>, IMayHaveTenant, ISoftDelete
    {
        /// <summary>
        /// TenantId of this entity.
        /// </summary>
        public virtual string TenantId { get; set; }

        /// <summary>
        /// Id of the Role.
        /// </summary>
        public virtual string RoleId { get; set; }

        /// <summary>
        /// Id of the <see cref="OrganizationUnit"/>.
        /// </summary>
        public virtual string OrganizationUnitId { get; set; }

        /// <summary>
        /// Specifies if the organization is soft deleted or not.
        /// </summary>
        public virtual bool IsDeleted { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="OrganizationUnitRole"/> class.
        /// </summary>
        public OrganizationUnitRole()
        {
            
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="OrganizationUnitRole"/> class.
        /// </summary>
        /// <param name="tenantId">TenantId</param>
        /// <param name="roleId">Id of the User.</param>
        /// <param name="organizationUnitId">Id of the <see cref="OrganizationUnit"/>.</param>
        public OrganizationUnitRole(string tenantId, string roleId, string organizationUnitId)
        {
            TenantId = tenantId;
            RoleId = roleId;
            OrganizationUnitId = organizationUnitId;
        }
    }
}
