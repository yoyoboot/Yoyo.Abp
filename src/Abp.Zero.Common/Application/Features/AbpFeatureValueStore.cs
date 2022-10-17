using System.Globalization;
using System.Threading.Tasks;
using Abp.Application.Editions;
using Abp.Authorization.Users;
using Abp.Collections.Extensions;
using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.Domain.Uow;
using Abp.Events.Bus.Entities;
using Abp.Events.Bus.Handlers;
using Abp.Localization;
using Abp.MultiTenancy;
using Abp.Runtime.Caching;
using Abp.UI;
using Abp.Zero;

namespace Abp.Application.Features
{
    /// <summary>
    /// Implements <see cref="IFeatureValueStore"/>.
    /// </summary>
    public class AbpFeatureValueStore<TTenant, TUser> :
        IAbpZeroFeatureValueStore,
        ITransientDependency,
        IEventHandler<EntityChangingEventData<Edition>>,
        IEventHandler<EntityChangingEventData<EditionFeatureSetting>>,
        IEventHandler<EntityChangingEventData<TenantFeatureSetting>>

        where TTenant : AbpTenant<TUser>
        where TUser : AbpUserBase
    {
        private readonly ICacheManager _cacheManager;
        private readonly IRepository<TenantFeatureSetting, string> _tenantFeatureRepository;
        private readonly IRepository<TTenant> _tenantRepository;
        private readonly IRepository<EditionFeatureSetting, string> _editionFeatureRepository;
        private readonly IFeatureManager _featureManager;
        private readonly IUnitOfWorkManager _unitOfWorkManager;

        public ILocalizationManager LocalizationManager { get; set; }
        protected string LocalizationSourceName { get; set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="AbpFeatureValueStore{TTenant, TUser}"/> class.
        /// </summary>
        public AbpFeatureValueStore(
            ICacheManager cacheManager,
            IRepository<TenantFeatureSetting, string> tenantFeatureRepository,
            IRepository<TTenant> tenantRepository,
            IRepository<EditionFeatureSetting, string> editionFeatureRepository,
            IFeatureManager featureManager,
            IUnitOfWorkManager unitOfWorkManager)
        {
            _cacheManager = cacheManager;
            _tenantFeatureRepository = tenantFeatureRepository;
            _tenantRepository = tenantRepository;
            _editionFeatureRepository = editionFeatureRepository;
            _featureManager = featureManager;
            _unitOfWorkManager = unitOfWorkManager;

            LocalizationManager = NullLocalizationManager.Instance;
            LocalizationSourceName = AbpZeroConsts.LocalizationSourceName;
        }

        /// <inheritdoc/>
        public virtual Task<string> GetValueOrNullAsync(string tenantId, Feature feature)
        {
            return GetValueOrNullAsync(tenantId, feature.Name);
        }

        /// <inheritdoc/>
        public virtual string GetValueOrNull(string tenantId, Feature feature)
        {
            return GetValueOrNull(tenantId, feature.Name);
        }

        public virtual async Task<string> GetEditionValueOrNullAsync(string editionId, string featureName)
        {
            var cacheItem = await GetEditionFeatureCacheItemAsync(editionId);
            return cacheItem.FeatureValues.GetOrDefault(featureName);
        }

        public virtual string GetEditionValueOrNull(string editionId, string featureName)
        {
            var cacheItem = GetEditionFeatureCacheItem(editionId);
            return cacheItem.FeatureValues.GetOrDefault(featureName);
        }

        public virtual async Task<string> GetValueOrNullAsync(string tenantId, string featureName)
        {
            var cacheItem = await GetTenantFeatureCacheItemAsync(tenantId);
            var value = cacheItem.FeatureValues.GetOrDefault(featureName);
            if (value != null)
            {
                return value;
            }

            if (cacheItem.EditionId.HasValue())
            {
                value = await GetEditionValueOrNullAsync(cacheItem.EditionId, featureName);
                if (value != null)
                {
                    return value;
                }
            }

            return null;
        }

        public virtual string GetValueOrNull(string tenantId, string featureName)
        {
            var cacheItem = GetTenantFeatureCacheItem(tenantId);
            var value = cacheItem.FeatureValues.GetOrDefault(featureName);
            if (value != null)
            {
                return value;
            }

            if (cacheItem.EditionId.HasValue())
            {
                value = GetEditionValueOrNull(cacheItem.EditionId, featureName);
                if (value != null)
                {
                    return value;
                }
            }

            return null;
        }
        
        public virtual async Task SetEditionFeatureValueAsync(string editionId, string featureName, string value)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                using (_unitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    if (await GetEditionValueOrNullAsync(editionId, featureName) == value)
                    {
                        return;
                    }

                    var currentFeature = await _editionFeatureRepository.FirstOrDefaultAsync(f => f.EditionId == editionId && f.Name == featureName);

                    var feature = _featureManager.GetOrNull(featureName);
                    if (feature == null || feature.DefaultValue == value)
                    {
                        if (currentFeature != null)
                        {
                            await _editionFeatureRepository.DeleteAsync(currentFeature);
                        }

                        return;
                    }

                    if (!feature.InputType.Validator.IsValid(value))
                    {
                        throw new UserFriendlyException(string.Format(
                            L("InvalidFeatureValue"), feature.Name));
                    }

                    if (currentFeature == null)
                    {
                        await _editionFeatureRepository.InsertAsync(new EditionFeatureSetting(editionId, featureName, value));
                    }
                    else
                    {
                        currentFeature.Value = value;
                    }
                }
            });
        }
        
        public virtual void SetEditionFeatureValue(string editionId, string featureName, string value)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    if (GetEditionValueOrNull(editionId, featureName) == value)
                    {
                        return;
                    }

                    var currentFeature = _editionFeatureRepository.FirstOrDefault(f => f.EditionId == editionId && f.Name == featureName);

                    var feature = _featureManager.GetOrNull(featureName);
                    if (feature == null || feature.DefaultValue == value)
                    {
                        if (currentFeature != null)
                        {
                            _editionFeatureRepository.Delete(currentFeature);
                        }

                        return;
                    }

                    if (currentFeature == null)
                    {
                        _editionFeatureRepository.Insert(new EditionFeatureSetting(editionId, featureName, value));
                    }
                    else
                    {
                        currentFeature.Value = value;
                    }
                }
            });
        }

        protected virtual async Task<TenantFeatureCacheItem> GetTenantFeatureCacheItemAsync(string tenantId)
        {
            return await _cacheManager.GetTenantFeatureCache().GetAsync(tenantId, async () =>
            {
                TTenant tenant;
                using (var uow = _unitOfWorkManager.Begin())
                {
                    using (_unitOfWorkManager.Current.SetTenantId(null))
                    {
                        tenant = await _tenantRepository.GetAsync(tenantId);

                        await uow.CompleteAsync();
                    }
                }

                var newCacheItem = new TenantFeatureCacheItem { EditionId = tenant.EditionId };

                using (var uow = _unitOfWorkManager.Begin())
                {
                    using (_unitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                    using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                    {
                        var featureSettings = await _tenantFeatureRepository.GetAllListAsync();
                        foreach (var featureSetting in featureSettings)
                        {
                            newCacheItem.FeatureValues[featureSetting.Name] = featureSetting.Value;
                        }

                        await uow.CompleteAsync();
                    }
                }

                return newCacheItem;
            });
        }

        protected virtual TenantFeatureCacheItem GetTenantFeatureCacheItem(string tenantId)
        {
            return _cacheManager.GetTenantFeatureCache().Get(tenantId, () =>
            {
                TTenant tenant;
                using (var uow = _unitOfWorkManager.Begin())
                {
                    using (_unitOfWorkManager.Current.SetTenantId(null))
                    {
                        tenant = _tenantRepository.Get(tenantId);

                        uow.Complete();
                    }
                }

                var newCacheItem = new TenantFeatureCacheItem { EditionId = tenant.EditionId };

                using (var uow = _unitOfWorkManager.Begin())
                {
                    using (_unitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                    using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                    {
                        var featureSettings = _tenantFeatureRepository.GetAllList();
                        foreach (var featureSetting in featureSettings)
                        {
                            newCacheItem.FeatureValues[featureSetting.Name] = featureSetting.Value;
                        }

                        uow.Complete();
                    }
                }

                return newCacheItem;
            });
        }

        protected virtual async Task<EditionfeatureCacheItem> GetEditionFeatureCacheItemAsync(string editionId)
        {
            return await _cacheManager
                .GetEditionFeatureCache()
                .GetAsync(
                    editionId,
                    async () => await CreateEditionFeatureCacheItemAsync(editionId)
                );
        }

        protected virtual EditionfeatureCacheItem GetEditionFeatureCacheItem(string editionId)
        {
            return _cacheManager
                .GetEditionFeatureCache()
                .Get(
                    editionId,
                    () => CreateEditionFeatureCacheItem(editionId)
                );
        }

        protected virtual async Task<EditionfeatureCacheItem> CreateEditionFeatureCacheItemAsync(string editionId)
        {
            var newCacheItem = new EditionfeatureCacheItem();

            using (var uow = _unitOfWorkManager.Begin())
            {
                using (_unitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    var featureSettings = await _editionFeatureRepository.GetAllListAsync(f => f.EditionId == editionId);
                    foreach (var featureSetting in featureSettings)
                    {
                        newCacheItem.FeatureValues[featureSetting.Name] = featureSetting.Value;
                    }

                    await uow.CompleteAsync();
                }
            }

            return newCacheItem;
        }

        protected virtual EditionfeatureCacheItem CreateEditionFeatureCacheItem(string editionId)
        {
            var newCacheItem = new EditionfeatureCacheItem();

            using (var uow = _unitOfWorkManager.Begin())
            {
                using (_unitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    var featureSettings = _editionFeatureRepository.GetAllList(f => f.EditionId == editionId);
                    foreach (var featureSetting in featureSettings)
                    {
                        newCacheItem.FeatureValues[featureSetting.Name] = featureSetting.Value;
                    }

                    uow.Complete();
                }
            }

            return newCacheItem;
        }

        public virtual void HandleEvent(EntityChangingEventData<EditionFeatureSetting> eventData)
        {
            _cacheManager.GetEditionFeatureCache().Remove(eventData.Entity.EditionId);
        }

        public virtual void HandleEvent(EntityChangingEventData<Edition> eventData)
        {
            if (eventData.Entity.IsTransient())
            {
                return;
            }

            _cacheManager.GetEditionFeatureCache().Remove(eventData.Entity.Id);
        }

        public virtual void HandleEvent(EntityChangingEventData<TenantFeatureSetting> eventData)
        {
            if (eventData.Entity.TenantId.HasValue())
            {
                _cacheManager.GetTenantFeatureCache().Remove(eventData.Entity.TenantId);
            }
        }

        protected virtual string L(string name)
        {
            return LocalizationManager.GetString(LocalizationSourceName, name);
        }

        protected virtual string L(string name, CultureInfo cultureInfo)
        {
            return LocalizationManager.GetString(LocalizationSourceName, name, cultureInfo);
        }
    }
}
