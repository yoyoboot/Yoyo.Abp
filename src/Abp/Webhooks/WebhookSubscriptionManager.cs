using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Authorization;
using Abp.Collections.Extensions;
using Abp.Domain.Services;
using Abp.Domain.Uow;
using Abp.Json;
using Abp.Webhooks.Extensions;

namespace Abp.Webhooks
{
    public class WebhookSubscriptionManager : DomainService, IWebhookSubscriptionManager
    {
        public IWebhookSubscriptionsStore WebhookSubscriptionsStore { get; set; }

        private readonly IGuidGenerator _guidGenerator;

        private readonly IWebhookDefinitionManager _webhookDefinitionManager;

        private const string WebhookSubscriptionSecretPrefix = "whs_";

        public WebhookSubscriptionManager(
            IGuidGenerator guidGenerator,
            IWebhookDefinitionManager webhookDefinitionManager)
        {
            _guidGenerator = guidGenerator;
            _webhookDefinitionManager = webhookDefinitionManager;

            WebhookSubscriptionsStore = NullWebhookSubscriptionsStore.Instance;
        }

        public virtual async Task<WebhookSubscription> GetAsync(Guid id)
        {
            return (await WebhookSubscriptionsStore.GetAsync(id)).ToWebhookSubscription();
        }

        public virtual WebhookSubscription Get(Guid id)
        {
            return WebhookSubscriptionsStore.Get(id).ToWebhookSubscription();
        }

        public virtual async Task<List<WebhookSubscription>> GetAllSubscriptionsAsync(string tenantId)
        {
            return (await WebhookSubscriptionsStore.GetAllSubscriptionsAsync(tenantId))
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual List<WebhookSubscription> GetAllSubscriptions(string tenantId)
        {
            return WebhookSubscriptionsStore.GetAllSubscriptions(tenantId)
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual async Task<List<WebhookSubscription>> GetAllSubscriptionsIfFeaturesGrantedAsync(string tenantId, string webhookName)
        {
            if (!await _webhookDefinitionManager.IsAvailableAsync(tenantId, webhookName))
            {
                return new List<WebhookSubscription>();
            }

            return (await WebhookSubscriptionsStore.GetAllSubscriptionsAsync(tenantId, webhookName))
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual List<WebhookSubscription> GetAllSubscriptionsIfFeaturesGranted(string tenantId, string webhookName)
        {
            if (!_webhookDefinitionManager.IsAvailable(tenantId, webhookName))
            {
                return new List<WebhookSubscription>();
            }

            return WebhookSubscriptionsStore.GetAllSubscriptions(tenantId, webhookName)
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual async Task<List<WebhookSubscription>> GetAllSubscriptionsOfTenantsAsync(string[] tenantIds)
        {
            return (await WebhookSubscriptionsStore.GetAllSubscriptionsOfTenantsAsync(tenantIds))
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual List<WebhookSubscription> GetAllSubscriptionsOfTenants(string[] tenantIds)
        {
            return WebhookSubscriptionsStore.GetAllSubscriptionsOfTenants(tenantIds)
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual async Task<List<WebhookSubscription>> GetAllSubscriptionsOfTenantsIfFeaturesGrantedAsync(string[] tenantIds, string webhookName)
        {
            var featureGrantedTenants = new List<string>();
            foreach (var tenantId in tenantIds)
            {
                if (await _webhookDefinitionManager.IsAvailableAsync(tenantId, webhookName))
                {
                    featureGrantedTenants.Add(tenantId);
                }
            }

            return (await WebhookSubscriptionsStore.GetAllSubscriptionsOfTenantsAsync(featureGrantedTenants.ToArray(), webhookName))
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual List<WebhookSubscription> GetAllSubscriptionsOfTenantsIfFeaturesGranted(string[] tenantIds, string webhookName)
        {
            var featureGrantedTenants = new List<string>();
            foreach (var tenantId in tenantIds)
            {
                if (_webhookDefinitionManager.IsAvailable(tenantId, webhookName))
                {
                    featureGrantedTenants.Add(tenantId);
                }
            }

            return WebhookSubscriptionsStore.GetAllSubscriptionsOfTenants(featureGrantedTenants.ToArray(), webhookName)
                .Select(subscriptionInfo => subscriptionInfo.ToWebhookSubscription()).ToList();
        }

        public virtual async Task<bool> IsSubscribedAsync(string tenantId, string webhookName)
        {
            if (!await _webhookDefinitionManager.IsAvailableAsync(tenantId, webhookName))
            {
                return false;
            }

            return await WebhookSubscriptionsStore.IsSubscribedAsync(tenantId, webhookName);
        }

        public virtual bool IsSubscribed(string tenantId, string webhookName)
        {
            if (!_webhookDefinitionManager.IsAvailable(tenantId, webhookName))
            {
                return false;
            }

            return WebhookSubscriptionsStore.IsSubscribed(tenantId, webhookName);
        }
        
        public virtual async Task AddOrUpdateSubscriptionAsync(WebhookSubscription webhookSubscription)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await CheckIfPermissionsGrantedAsync(webhookSubscription);

                if (webhookSubscription.Id == default)
                {
                    webhookSubscription.Id = _guidGenerator.Create();
                    webhookSubscription.Secret = WebhookSubscriptionSecretPrefix + Guid.NewGuid().ToString("N");
                    await WebhookSubscriptionsStore.InsertAsync(webhookSubscription.ToWebhookSubscriptionInfo());
                }
                else
                {
                    var subscription = await WebhookSubscriptionsStore.GetAsync(webhookSubscription.Id);
                    subscription.WebhookUri = webhookSubscription.WebhookUri;
                    subscription.Webhooks = webhookSubscription.Webhooks.ToJsonString();
                    subscription.Headers = webhookSubscription.Headers.ToJsonString();
                    await WebhookSubscriptionsStore.UpdateAsync(subscription);
                }
            });
        }
        
        public virtual void AddOrUpdateSubscription(WebhookSubscription webhookSubscription)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                CheckIfPermissionsGranted(webhookSubscription);

                if (webhookSubscription.Id == default)
                {
                    webhookSubscription.Id = _guidGenerator.Create();
                    webhookSubscription.Secret = WebhookSubscriptionSecretPrefix + Guid.NewGuid().ToString("N");
                    WebhookSubscriptionsStore.Insert(webhookSubscription.ToWebhookSubscriptionInfo());
                }
                else
                {
                    var subscription = WebhookSubscriptionsStore.Get(webhookSubscription.Id);
                    subscription.WebhookUri = webhookSubscription.WebhookUri;
                    subscription.Webhooks = webhookSubscription.Webhooks.ToJsonString();
                    subscription.Headers = webhookSubscription.Headers.ToJsonString();
                    WebhookSubscriptionsStore.Update(subscription);
                }
            });
        }

        public virtual async Task ActivateWebhookSubscriptionAsync(Guid id, bool active)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                var webhookSubscription = await WebhookSubscriptionsStore.GetAsync(id);
                webhookSubscription.IsActive = active;
            });
        }
        
        public virtual async Task DeleteSubscriptionAsync(Guid id)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await WebhookSubscriptionsStore.DeleteAsync(id);
            });
        }
        
        public virtual void DeleteSubscription(Guid id)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                WebhookSubscriptionsStore.Delete(id);
            });
        }
        
        public virtual async Task AddWebhookAsync(WebhookSubscriptionInfo subscription, string webhookName)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await CheckPermissionsAsync(subscription.TenantId, webhookName);
                subscription.SubscribeWebhook(webhookName);
            });
        }
        
        public virtual void AddWebhook(WebhookSubscriptionInfo subscription, string webhookName)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                CheckPermissions(subscription.TenantId, webhookName);
                subscription.SubscribeWebhook(webhookName);
            });
        }

        #region PermissionCheck

        protected virtual async Task CheckIfPermissionsGrantedAsync(WebhookSubscription webhookSubscription)
        {
            if (webhookSubscription.Webhooks.IsNullOrEmpty())
            {
                return;
            }

            foreach (var webhookDefinition in webhookSubscription.Webhooks)
            {
                await CheckPermissionsAsync(webhookSubscription.TenantId, webhookDefinition);
            }
        }

        protected virtual async Task CheckPermissionsAsync(string tenantId, string webhookName)
        {
            if (!await _webhookDefinitionManager.IsAvailableAsync(tenantId, webhookName))
            {
                throw new AbpAuthorizationException($"Tenant \"{tenantId}\" must have necessary feature(s) to use webhook \"{webhookName}\"");
            }
        }

        protected virtual void CheckIfPermissionsGranted(WebhookSubscription webhookSubscription)
        {
            if (webhookSubscription.Webhooks.IsNullOrEmpty())
            {
                return;
            }

            foreach (var webhookDefinition in webhookSubscription.Webhooks)
            {
                CheckPermissions(webhookSubscription.TenantId, webhookDefinition);
            }
        }

        protected virtual void CheckPermissions(string tenantId, string webhookName)
        {
            if (!_webhookDefinitionManager.IsAvailable(tenantId, webhookName))
            {
                throw new AbpAuthorizationException($"Tenant \"{tenantId}\" must have necessary feature(s) to use webhook \"{webhookName}\"");
            }
        }

        #endregion
    }
}
