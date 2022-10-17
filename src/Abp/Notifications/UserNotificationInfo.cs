using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using Abp.Domain.Entities;
using Abp.Domain.Entities.Auditing;
using Abp.Extensions;
using Abp.Timing;

namespace Abp.Notifications
{
    /// <summary>
    /// Used to store a user notification.
    /// </summary>
    [Serializable]
    [Table("AbpUserNotifications")]
    public class UserNotificationInfo : Entity<Guid>, IHasCreationTime, IMayHaveTenant
    {
        /// <summary>
        /// Tenant Id.
        /// </summary>
        public virtual string TenantId { get; set; }

        /// <summary>
        /// User Id.
        /// </summary>
        public virtual string UserId { get; set; }

        /// <summary>
        /// Notification Id.
        /// </summary>
        [Required]
        public virtual Guid TenantNotificationId { get; set; }

        /// <summary>
        /// Current state of the user notification.
        /// </summary>
        public virtual UserNotificationState State { get; set; }

        public virtual DateTime CreationTime { get; set; }

        /// <summary>
        /// which realtime notifiers should handle this notification
        /// </summary>
        public string TargetNotifiers { get; set; }

        [NotMapped]
        public List<string> TargetNotifiersList => TargetNotifiers.IsNullOrWhiteSpace()
            ? new List<string>()
            : TargetNotifiers.Split(NotificationInfo.NotificationTargetSeparator).ToList();

        public UserNotificationInfo()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="UserNotificationInfo"/> class.
        /// </summary>
        /// <param name="id"></param>
        public UserNotificationInfo(Guid id)
        {
            Id = id;
            State = UserNotificationState.Unread;
            CreationTime = Clock.Now;
        }

        public void SetTargetNotifiers(List<string> list)
        {
            TargetNotifiers = string.Join(NotificationInfo.NotificationTargetSeparator.ToString(), list);
        }
    }
}
