using System;
using System.Threading.Tasks;
using Abp.AspNetCore.SignalR.Hubs;
using Abp.Dependency;
using Abp.Notifications;
using Abp.RealTime;
using Castle.Core.Logging;
using Microsoft.AspNetCore.SignalR;

namespace Abp.AspNetCore.SignalR.Notifications
{
    /// <summary>
    /// Implements <see cref="IRealTimeNotifier"/> to send notifications via SignalR.
    /// </summary>
    public class SignalRRealTimeNotifier : IRealTimeNotifier, ITransientDependency
    {
        public bool UseOnlyIfRequestedAsTarget => false;
        
        /// <summary>
        /// Reference to the logger.
        /// </summary>
        public ILogger Logger { get; set; }

        private readonly IOnlineClientManager _onlineClientManager;

        private readonly IHubContext<AbpCommonHub> _hubContext;

        /// <summary>
        /// Initializes a new instance of the <see cref="SignalRRealTimeNotifier"/> class.
        /// </summary>
        public SignalRRealTimeNotifier(
            IOnlineClientManager onlineClientManager,
            IHubContext<AbpCommonHub> hubContext)
        {
            _onlineClientManager = onlineClientManager;
            _hubContext = hubContext;
            Logger = NullLogger.Instance;
        }

        /// <inheritdoc/>
        public async Task SendNotificationsAsync(UserNotification[] userNotifications)
        {
            foreach (var userNotification in userNotifications)
            {
                try
                {
                    var onlineClients = _onlineClientManager.GetAllByUserId(userNotification);
                    foreach (var onlineClient in onlineClients)
                    {
                        var signalRClient = _hubContext.Clients.Client(onlineClient.ConnectionId);
                        if (signalRClient == null)
                        {
                            Logger.Debug("Can not get user " + userNotification.ToUserIdentifier() + " with connectionId " + onlineClient.ConnectionId + " from SignalR hub!");
                            continue;
                        }

#pragma warning disable CS0618 // Type or member is obsolete, this line will be removed once the EntityType property is removed
						userNotification.Notification.EntityType = null; // Serialization of System.Type causes SignalR to disconnect. See https://github.com/aspnetboilerplate/aspnetboilerplate/issues/5230
#pragma warning restore CS0618 // Type or member is obsolete, this line will be removed once the EntityType property is removed
                        await signalRClient.SendAsync("getNotification", userNotification);
                    }
                }
                catch (Exception ex)
                {
                    Logger.Warn("Could not send notification to user: " + userNotification.ToUserIdentifier());
                    Logger.Warn(ex.ToString(), ex);
                }
            }
        }
    }
}
