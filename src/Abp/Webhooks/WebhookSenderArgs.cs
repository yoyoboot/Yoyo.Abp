using System;
using System.Collections.Generic;

namespace Abp.Webhooks
{
    public class WebhookSenderArgs
    {
        public string TenantId { get; set; }

        //Webhook information 

        /// <summary>
        /// <see cref="WebhookEvent"/> foreign id 
        /// </summary>
        public Guid WebhookEventId { get; set; }

        /// <summary>
        /// Webhook unique name
        /// </summary>
        public string WebhookName { get; set; }

        /// <summary>
        /// Webhook data as JSON string.
        /// </summary>
        public string Data { get; set; }

        //Subscription information

        /// <summary>
        /// <see cref="WebhookSubscription"/> foreign id 
        /// </summary>
        public Guid WebhookSubscriptionId { get; set; }

        /// <summary>
        /// Subscription webhook endpoint
        /// </summary>
        public string WebhookUri { get; set; }

        /// <summary>
        /// Webhook secret
        /// </summary>
        public string Secret { get; set; }

        /// <summary>
        /// Gets a set of additional HTTP headers.That headers will be sent with the webhook.
        /// </summary>
        public IDictionary<string, string> Headers { get; set; }

        /// <summary>
        /// Tries to send webhook only one time without checking to send attempt count
        /// </summary>
        public bool TryOnce { get; set; }

        /// <summary>
        /// True: It sends the exact same data as the parameter to clients.
        /// <para>
        /// False: It sends data in <see cref="WebhookPayload"/>. It is recommended way.
        /// </para>
        /// </summary>
        public bool SendExactSameData { get; set; }

        public WebhookSenderArgs()
        {
            Headers = new Dictionary<string, string>();
        }
    }
}
