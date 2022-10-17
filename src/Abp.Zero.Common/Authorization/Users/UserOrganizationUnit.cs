using System.ComponentModel.DataAnnotations.Schema;
using Abp.Domain.Entities;
using Abp.Domain.Entities.Auditing;
using Abp.Organizations;

namespace Abp.Authorization.Users
{
    /// <summary>
    /// Represents membership of a User to an OU.
    /// </summary>
    [Table("AbpUserOrganizationUnits")]
    public class UserOrganizationUnit : CreationAuditedEntity<string>, IMayHaveTenant, ISoftDelete
    {
        /// <summary>
        /// TenantId of this entity.
        /// </summary>
        public virtual string TenantId { get; set; }

        /// <summary>
        /// Id of the User.
        /// </summary>
        public virtual string UserId { get; set; }

        /// <summary>
        /// Id of the <see cref="OrganizationUnit"/>.
        /// </summary>
        public virtual string OrganizationUnitId { get; set; }

        /// <summary>
        /// Specifies if the organization is soft deleted or not.
        /// </summary>
        public virtual bool IsDeleted { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="UserOrganizationUnit"/> class.
        /// </summary>
        public UserOrganizationUnit()
        {
            
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="UserOrganizationUnit"/> class.
        /// </summary>
        /// <param name="tenantId">TenantId</param>
        /// <param name="userId">Id of the User.</param>
        /// <param name="organizationUnitId">Id of the <see cref="OrganizationUnit"/>.</param>
        public UserOrganizationUnit(string tenantId, string userId, string organizationUnitId)
        {
            TenantId = tenantId;
            UserId = userId;
            OrganizationUnitId = organizationUnitId;
        }
    }
}
