using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Dependency;

namespace Abp.Notifications
{
    /// <summary>
    /// Implements  <see cref="IUserNotificationManager"/>.
    /// </summary>
    public class UserNotificationManager : IUserNotificationManager, ISingletonDependency
    {
        private readonly INotificationStore _store;

        /// <summary>
        /// Initializes a new instance of the <see cref="UserNotificationManager"/> class.
        /// </summary>
        public UserNotificationManager(INotificationStore store)
        {
            _store = store;
        }

        public async Task<List<UserNotification>> GetUserNotificationsAsync(UserIdentifier user, UserNotificationState? state = null, int skipCount = 0, int maxResultCount = int.MaxValue, DateTime? startDate = null, DateTime? endDate = null)
        {
            var userNotifications = await _store.GetUserNotificationsWithNotificationsAsync(user, state, skipCount, maxResultCount, startDate, endDate);
            return userNotifications
                .Select(un => un.ToUserNotification())
                .ToList();
        }

        public List<UserNotification> GetUserNotifications(UserIdentifier user, UserNotificationState? state = null, int skipCount = 0, int maxResultCount = int.MaxValue, DateTime? startDate = null, DateTime? endDate = null)
        {
            var userNotifications =  _store.GetUserNotificationsWithNotifications(user, state, skipCount, maxResultCount, startDate, endDate);
            return userNotifications
                .Select(un => un.ToUserNotification())
                .ToList();
        }

        public Task<int> GetUserNotificationCountAsync(UserIdentifier user, UserNotificationState? state = null, DateTime? startDate = null, DateTime? endDate = null)
        {
            return _store.GetUserNotificationCountAsync(user, state, startDate, endDate);
        }

        public int GetUserNotificationCount(UserIdentifier user, UserNotificationState? state = null, DateTime? startDate = null, DateTime? endDate = null)
        {
            return _store.GetUserNotificationCount(user, state, startDate, endDate);
        }

        public async Task<UserNotification> GetUserNotificationAsync(string tenantId, Guid userNotificationId)
        {
            var userNotification = await _store.GetUserNotificationWithNotificationOrNullAsync(tenantId, userNotificationId);
            if (userNotification == null)
            {
                return null;
            }

            return userNotification.ToUserNotification();
        }

        public UserNotification GetUserNotification(string tenantId, Guid userNotificationId)
        {
            var userNotification =  _store.GetUserNotificationWithNotificationOrNull(tenantId, userNotificationId);
            if (userNotification == null)
            {
                return null;
            }

            return userNotification.ToUserNotification();
        }

        public Task UpdateUserNotificationStateAsync(string tenantId, Guid userNotificationId, UserNotificationState state)
        {
            return _store.UpdateUserNotificationStateAsync(tenantId, userNotificationId, state);
        }

        public void UpdateUserNotificationState(string tenantId, Guid userNotificationId, UserNotificationState state)
        {
            _store.UpdateUserNotificationState(tenantId, userNotificationId, state);
        }

        public Task UpdateAllUserNotificationStatesAsync(UserIdentifier user, UserNotificationState state)
        {
            return _store.UpdateAllUserNotificationStatesAsync(user, state);
        }

        public void UpdateAllUserNotificationStates(UserIdentifier user, UserNotificationState state)
        {
            _store.UpdateAllUserNotificationStates(user, state);
        }

        public Task DeleteUserNotificationAsync(string tenantId, Guid userNotificationId)
        {
            return _store.DeleteUserNotificationAsync(tenantId, userNotificationId);
        }

        
        public void DeleteUserNotification(string tenantId, Guid userNotificationId)
        {
            _store.DeleteUserNotification(tenantId, userNotificationId);
        }

        public Task DeleteAllUserNotificationsAsync(UserIdentifier user, UserNotificationState? state = null, DateTime? startDate = null, DateTime? endDate = null)
        {
            return _store.DeleteAllUserNotificationsAsync(user, state, startDate, endDate);
        }

        public void DeleteAllUserNotifications(UserIdentifier user, UserNotificationState? state = null, DateTime? startDate = null, DateTime? endDate = null)
        {
            _store.DeleteAllUserNotifications(user, state, startDate, endDate);
        }
    }
}
