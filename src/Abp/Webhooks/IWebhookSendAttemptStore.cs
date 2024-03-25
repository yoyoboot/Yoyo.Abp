using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Abp.Application.Services.Dto;

namespace Abp.Webhooks
{
    public interface IWebhookSendAttemptStore
    {
        Task InsertAsync(WebhookSendAttempt webhookSendAttempt);

        void Insert(WebhookSendAttempt webhookSendAttempt);

        Task UpdateAsync(WebhookSendAttempt webhookSendAttempt);

        void Update(WebhookSendAttempt webhookSendAttempt);

        Task DeleteAsync(WebhookSendAttempt webhookSendAttempt);

        void Delete(WebhookSendAttempt webhookSendAttempt);

        Task<WebhookSendAttempt> GetAsync(string tenantId, Guid id);

        WebhookSendAttempt Get(string tenantId, Guid id);

        /// <summary>
        /// Returns work item count by given web hook id and subscription id, (How many times publisher tried to send web hook)
        /// </summary>
        Task<int> GetSendAttemptCountAsync(string tenantId, Guid webhookId, Guid webhookSubscriptionId);

        /// <summary>
        /// Returns work item count by given web hook id and subscription id. (How many times publisher tried to send web hook)
        /// </summary>
        int GetSendAttemptCount(string tenantId, Guid webhookId, Guid webhookSubscriptionId);

        /// <summary>
        /// Checks is there any successful webhook attempt in last <paramref name="searchCount"/> items. Should return true if there are not X number items
        /// </summary>
        Task<bool> HasXConsecutiveFailAsync(string tenantId, Guid subscriptionId, int searchCount);

        Task<IPagedResult<WebhookSendAttempt>> GetAllSendAttemptsBySubscriptionAsPagedListAsync(string tenantId, Guid subscriptionId, int maxResultCount, int skipCount);

        IPagedResult<WebhookSendAttempt> GetAllSendAttemptsBySubscriptionAsPagedList(string tenantId, Guid subscriptionId, int maxResultCount, int skipCount);

        Task<List<WebhookSendAttempt>> GetAllSendAttemptsByWebhookEventIdAsync(string tenantId, Guid webhookEventId);

        List<WebhookSendAttempt> GetAllSendAttemptsByWebhookEventId(string tenantId, Guid webhookEventId);

    }
}
