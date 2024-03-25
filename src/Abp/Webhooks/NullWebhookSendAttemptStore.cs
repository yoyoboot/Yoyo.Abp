using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Abp.Application.Services.Dto;

namespace Abp.Webhooks
{
    public class NullWebhookSendAttemptStore : IWebhookSendAttemptStore
    {
        public static NullWebhookSendAttemptStore Instance = new NullWebhookSendAttemptStore();

        public Task InsertAsync(WebhookSendAttempt webhookSendAttempt)
        {
            return Task.CompletedTask;
        }

        public void Insert(WebhookSendAttempt webhookSendAttempt)
        {
        }

        public Task UpdateAsync(WebhookSendAttempt webhookSendAttempt)
        {
            return Task.CompletedTask;
        }

        public void Update(WebhookSendAttempt webhookSendAttempt)
        {
        }

        public Task DeleteAsync(WebhookSendAttempt webhookSendAttempt)
        {
            return Task.CompletedTask;
        }

        public void Delete(WebhookSendAttempt webhookSendAttempt)
        {
            
        }

        public Task<WebhookSendAttempt> GetAsync(string tenantId, Guid id)
        {
            return Task.FromResult<WebhookSendAttempt>(default);
        }

        public WebhookSendAttempt Get(string tenantId, Guid id)
        {
            return default;
        }

        public Task<int> GetSendAttemptCountAsync(string tenantId, Guid webhookId, Guid webhookSubscriptionId)
        {
            return Task.FromResult(int.MaxValue);
        }

        public int GetSendAttemptCount(string tenantId, Guid webhookId, Guid webhookSubscriptionId)
        {
            return int.MaxValue;
        }

        public Task<bool> HasXConsecutiveFailAsync(string tenantId, Guid subscriptionId, int searchCount)
        {
            return default;
        }

        public Task<IPagedResult<WebhookSendAttempt>> GetAllSendAttemptsBySubscriptionAsPagedListAsync(string tenantId, Guid subscriptionId, int maxResultCount,
            int skipCount)
        {
            return Task.FromResult(new PagedResultDto<WebhookSendAttempt>() as IPagedResult<WebhookSendAttempt>);
        }

        public IPagedResult<WebhookSendAttempt> GetAllSendAttemptsBySubscriptionAsPagedList(string tenantId, Guid subscriptionId, int maxResultCount,
            int skipCount)
        {
            return new PagedResultDto<WebhookSendAttempt>();
        }

        public Task<List<WebhookSendAttempt>> GetAllSendAttemptsByWebhookEventIdAsync(string tenantId, Guid webhookEventId)
        {
            return Task.FromResult(new List<WebhookSendAttempt>());
        }

        public List<WebhookSendAttempt> GetAllSendAttemptsByWebhookEventId(string tenantId, Guid webhookEventId)
        {
            return new List<WebhookSendAttempt>();
        }
    }
}
