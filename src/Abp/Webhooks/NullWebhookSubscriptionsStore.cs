using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.Webhooks
{
    /// <summary>
    /// Null pattern implementation of <see cref="IWebhookSubscriptionsStore"/>.
    /// It's used if <see cref="IWebhookSubscriptionsStore"/> is not implemented by actual persistent store
    /// </summary>
    public class NullWebhookSubscriptionsStore : IWebhookSubscriptionsStore
    {
        public static NullWebhookSubscriptionsStore Instance { get; } = new NullWebhookSubscriptionsStore();

        public Task<WebhookSubscriptionInfo> GetAsync(Guid id)
        {
            return Task.FromResult<WebhookSubscriptionInfo>(default);
        }

        public WebhookSubscriptionInfo Get(Guid id)
        {
            return default;
        }

        public Task InsertAsync(WebhookSubscriptionInfo webhookSubscription)
        {
            return Task.CompletedTask;
        }

        public void Insert(WebhookSubscriptionInfo webhookSubscription)
        {
        }

        public Task UpdateAsync(WebhookSubscriptionInfo webhookSubscription)
        {
            return Task.CompletedTask;
        }

        public void Update(WebhookSubscriptionInfo webhookSubscription)
        {
        }

        public Task DeleteAsync(Guid id)
        {
            return Task.CompletedTask;
        }

        public void Delete(Guid id)
        {
        }

        public Task<List<WebhookSubscriptionInfo>> GetAllSubscriptionsAsync(string tenantId)
        {
            return Task.FromResult(new List<WebhookSubscriptionInfo>());
        }

        public List<WebhookSubscriptionInfo> GetAllSubscriptions(string tenantId)
        {
            return new List<WebhookSubscriptionInfo>();
        }

        public Task<List<WebhookSubscriptionInfo>> GetAllSubscriptionsAsync(string tenantId, string webhookName)
        {
            return Task.FromResult(new List<WebhookSubscriptionInfo>());
        }

        public List<WebhookSubscriptionInfo> GetAllSubscriptions(string tenantId, string webhookName)
        {
            return new List<WebhookSubscriptionInfo>();
        }

        public Task<List<WebhookSubscriptionInfo>> GetAllSubscriptionsOfTenantsAsync(string[] tenantIds)
        {
            return Task.FromResult(new List<WebhookSubscriptionInfo>());
        }

        public List<WebhookSubscriptionInfo> GetAllSubscriptionsOfTenants(string[] tenantIds)
        {
            return new List<WebhookSubscriptionInfo>();
        }

        public Task<List<WebhookSubscriptionInfo>> GetAllSubscriptionsOfTenantsAsync(string[] tenantIds, string webhookName)
        {
            return Task.FromResult(new List<WebhookSubscriptionInfo>());
        }

        public List<WebhookSubscriptionInfo> GetAllSubscriptionsOfTenants(string[] tenantIds, string webhookName)
        {
            return new List<WebhookSubscriptionInfo>();
        }

        public Task<bool> IsSubscribedAsync(string tenantId, string webhookName)
        {
            return Task.FromResult(false);
        }

        public bool IsSubscribed(string tenantId, string webhookName)
        {
            return false;
        }
    }
}
