using System;
using System.Threading.Tasks;

namespace Abp.Webhooks
{
    public interface IWebhookSender
    {
        /// <summary>
        /// Tries to send webhook with given transactionId and stores process in <see cref="WebhookSendAttempt"/>
        /// Should throw exception if fails or response status not succeed
        /// </summary>
        /// <param name="webhookSenderArgs">arguments</param>
        /// <returns>Webhook send attempt id</returns>
        Task<Guid> SendWebhookAsync(WebhookSenderArgs webhookSenderArgs);
    }
}
