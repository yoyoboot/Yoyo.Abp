using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using Abp.Domain.Entities;
using Abp.Domain.Entities.Auditing;
using Abp.Extensions;
using Abp.Json;

namespace Abp.Notifications
{
    /// <summary>
    /// Used to store a notification subscription.
    /// </summary>
    [Table("AbpNotificationSubscriptions")]
    public class NotificationSubscriptionInfo : CreationAuditedEntity<Guid>, IMayHaveTenant
    {
        /// <summary>
        /// Tenant id of the subscribed user.
        /// </summary>
        public virtual string TenantId { get; set; }

        /// <summary>
        /// User Id.
        /// </summary>
        public virtual string UserId { get; set; }

        /// <summary>
        /// Notification unique name.
        /// </summary>
        [StringLength(NotificationInfo.MaxNotificationNameLength)]
        public virtual string NotificationName { get; set; }

        /// <summary>
        /// Gets/sets entity type name, if this is an entity level notification.
        /// It's FullName of the entity type.
        /// </summary>
        [StringLength(NotificationInfo.MaxEntityTypeNameLength)]
        public virtual string EntityTypeName { get; set; }

        /// <summary>
        /// AssemblyQualifiedName of the entity type.
        /// </summary>
        [StringLength(NotificationInfo.MaxEntityTypeAssemblyQualifiedNameLength)]
        public virtual string EntityTypeAssemblyQualifiedName { get; set; }

        /// <summary>
        /// Gets/sets primary key of the entity, if this is an entity level notification.
        /// </summary>
        [StringLength(NotificationInfo.MaxEntityIdLength)]
        public virtual string EntityId { get; set; }

        /// <summary>
        /// which realtime notifiers should handle this notification
        /// </summary>
        [StringLength(NotificationInfo.MaxTargetNotifiersLength)]
        public virtual string TargetNotifiers { get; set; }
        
        /// <summary>
        /// Initializes a new instance of the <see cref="NotificationSubscriptionInfo"/> class.
        /// </summary>
        public NotificationSubscriptionInfo()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="NotificationSubscriptionInfo"/> class.
        /// </summary>
        public NotificationSubscriptionInfo(
            Guid id, 
            string tenantId, 
            string userId, 
            string notificationName, 
            EntityIdentifier entityIdentifier = null,
            string targetNotifiers = null)
        {
            Id = id;
            TenantId = tenantId;
            NotificationName = notificationName;
            UserId = userId;
            EntityTypeName = entityIdentifier == null ? null : entityIdentifier.Type.FullName;
            EntityTypeAssemblyQualifiedName = entityIdentifier == null ? null : entityIdentifier.Type.AssemblyQualifiedName;
            EntityId = entityIdentifier == null ? null : entityIdentifier.Id.ToJsonString();
            TargetNotifiers = targetNotifiers;
        }
    }
}
