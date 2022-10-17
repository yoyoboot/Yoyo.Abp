using System.Threading.Tasks;
using Abp.Runtime.Session;

namespace Abp.Webhooks
{
    public interface IWebhookPublisher
    {
        /// <summary>
        /// Sends webhooks to current tenant subscriptions (<see cref="IAbpSession.TenantId"/>). with given data, (Checks permissions)
        /// </summary>
        /// <param name="webhookName"><see cref="WebhookDefinition.Name"/></param>
        /// <param name="data">data to send</param>
        /// <param name="sendExactSameData">
        /// True: It sends the exact same data as the parameter to clients.
        /// <para>
        /// False: It sends data in <see cref="WebhookPayload"/>. It is recommended way.
        /// </para>
        /// </param>
        /// <param name="headers">Headers to send. Publisher uses subscription defined webhook by default. You can add additional headers from here. If subscription already has given header, publisher uses the one you give here.</param>
        Task PublishAsync(string webhookName, object data, bool sendExactSameData = false, WebhookHeader headers = null);

        /// <summary>
        /// Sends webhooks to current tenant subscriptions (<see cref="IAbpSession.TenantId"/>). with given data, (Checks permissions)
        /// </summary>
        /// <param name="webhookName"><see cref="WebhookDefinition.Name"/></param>
        /// <param name="data">data to send</param>
        /// <param name="sendExactSameData">
        /// True: It sends the exact same data as the parameter to clients.
        /// <para>
        /// False: It sends data in <see cref="WebhookPayload"/>. It is recommended way.
        /// </para>
        /// </param>
        /// <param name="headers">Headers to send. Publisher uses subscription defined webhook by default. You can add additional headers from here. If subscription already has given header, publisher uses the one you give here.</param>
        void Publish(string webhookName, object data, bool sendExactSameData = false, WebhookHeader headers = null);

        /// <summary>
        /// Sends webhooks to given tenant's subscriptions
        /// </summary>
        /// <param name="webhookName"><see cref="WebhookDefinition.Name"/></param>
        /// <param name="data">data to send</param>
        /// <param name="tenantId">
        /// Target tenant id
        /// </param>
        /// <param name="sendExactSameData">
        /// True: It sends the exact same data as the parameter to clients.
        /// <para>
        /// False: It sends data in <see cref="WebhookPayload"/>. It is recommended way.
        /// </para>
        /// </param>
        /// <param name="headers">Headers to send. Publisher uses subscription defined webhook by default. You can add additional headers from here. If subscription already has given header, publisher uses the one you give here.</param>
        Task PublishAsync(string webhookName, object data, string tenantId, bool sendExactSameData = false, WebhookHeader headers = null);

        /// <summary>
        /// Sends webhooks to given tenant's subscriptions
        /// </summary>
        /// <param name="webhookName"><see cref="WebhookDefinition.Name"/></param>
        /// <param name="data">data to send</param>
        /// <param name="tenantId">
        /// Target tenant id
        /// </param>
        /// <param name="sendExactSameData">
        /// True: It sends the exact same data as the parameter to clients.
        /// <para>
        /// False: It sends data in <see cref="WebhookPayload"/>. It is recommended way.
        /// </para>
        /// </param>
        /// <param name="headers">Headers to send. Publisher uses subscription defined webhook by default. You can add additional headers from here. If subscription already has given header, publisher uses the one you give here.</param>
        void Publish(string webhookName, object data, string tenantId, bool sendExactSameData = false, WebhookHeader headers = null);

        /// <summary>
        /// Sends webhooks to given tenant's subscriptions
        /// </summary>
        /// <param name="webhookName"><see cref="WebhookDefinition.Name"/></param>
        /// <param name="data">data to send</param>
        /// <param name="tenantIds">
        /// Target tenant id(s)
        /// </param>
        /// <param name="sendExactSameData">
        /// True: It sends the exact same data as the parameter to clients.
        /// <para>
        /// False: It sends data in <see cref="WebhookPayload"/>. It is recommended way.
        /// </para>
        /// </param>
        /// <param name="headers">Headers to send. Publisher uses subscription defined webhook by default. You can add additional headers from here. If subscription already has given header, publisher uses the one you give here.</param>
        Task PublishAsync(string[] tenantIds, string webhookName, object data, bool sendExactSameData = false, WebhookHeader headers = null);

        /// <summary>
        /// Sends webhooks to given tenant's subscriptions
        /// </summary>
        /// <param name="webhookName"><see cref="WebhookDefinition.Name"/></param>
        /// <param name="data">data to send</param>
        /// <param name="tenantIds">
        /// Target tenant id(s)
        /// </param>
        /// <param name="sendExactSameData">
        /// True: It sends the exact same data as the parameter to clients.
        /// <para>
        /// False: It sends data in <see cref="WebhookPayload"/>. It is recommended way.
        /// </para>
        /// </param>
        /// <param name="headers">Headers to send. Publisher uses subscription defined webhook by default. You can add additional headers from here. If subscription already has given header, publisher uses the one you give here.</param>
        void Publish(string[] tenantIds, string webhookName, object data, bool sendExactSameData = false, WebhookHeader headers = null);
    }
}
