using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Abp.Application.Editions;
using Abp.Application.Features;
using Abp.Authorization.Users;
using Abp.Collections.Extensions;
using Abp.Domain.Repositories;
using Abp.Domain.Services;
using Abp.Domain.Uow;
using Abp.Events.Bus.Entities;
using Abp.Events.Bus.Handlers;
using Abp.Localization;
using Abp.Runtime.Caching;
using Abp.UI;
using Abp.Zero;

namespace Abp.MultiTenancy
{
    /// <summary>
    /// Tenant manager.
    /// Implements domain logic for <see cref="AbpTenant{TUser}"/>.
    /// </summary>
    /// <typeparam name="TTenant">Type of the application Tenant</typeparam>
    /// <typeparam name="TUser">Type of the application User</typeparam>
    public class AbpTenantManager<TTenant, TUser> : IDomainService,
        IEventHandler<EntityChangedEventData<TTenant>>,
        IEventHandler<EntityDeletedEventData<Edition>>
        where TTenant : AbpTenant<TUser>
        where TUser : AbpUserBase
    {
        public AbpEditionManager EditionManager { get; set; }

        public ILocalizationManager LocalizationManager { get; set; }

        protected string LocalizationSourceName { get; set; }

        public ICacheManager CacheManager { get; set; }

        public IFeatureManager FeatureManager { get; set; }

        public IUnitOfWorkManager UnitOfWorkManager { get; set; }

        protected IRepository<TTenant> TenantRepository { get; set; }

        protected IRepository<TenantFeatureSetting, string> TenantFeatureRepository { get; set; }

        private readonly IAbpZeroFeatureValueStore _featureValueStore;

        public AbpTenantManager(
            IRepository<TTenant> tenantRepository, 
            IRepository<TenantFeatureSetting, string> tenantFeatureRepository,
            AbpEditionManager editionManager,
            IAbpZeroFeatureValueStore featureValueStore)
        {
            _featureValueStore = featureValueStore;
            TenantRepository = tenantRepository;
            TenantFeatureRepository = tenantFeatureRepository;
            EditionManager = editionManager;
            LocalizationManager = NullLocalizationManager.Instance;
            LocalizationSourceName = AbpZeroConsts.LocalizationSourceName;
        }

        public virtual IQueryable<TTenant> Tenants { get { return TenantRepository.GetAll(); } }

        public virtual async Task CreateAsync(TTenant tenant)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await ValidateTenantAsync(tenant);

                if (await TenantRepository.FirstOrDefaultAsync(t => t.TenancyName == tenant.TenancyName) != null)
                {
                    throw new UserFriendlyException(string.Format(L("TenancyNameIsAlreadyTaken"), tenant.TenancyName));
                }

                await TenantRepository.InsertAsync(tenant);
            });
        }

        public virtual void Create(TTenant tenant)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                ValidateTenant(tenant);

                if (TenantRepository.FirstOrDefault(t => t.TenancyName == tenant.TenancyName) != null)
                {
                    throw new UserFriendlyException(string.Format(L("TenancyNameIsAlreadyTaken"), tenant.TenancyName));
                }

                TenantRepository.Insert(tenant);
            });
        }

        public virtual async Task UpdateAsync(TTenant tenant)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                if (await TenantRepository.FirstOrDefaultAsync(t => t.TenancyName == tenant.TenancyName && t.Id != tenant.Id) != null)
                {
                    throw new UserFriendlyException(string.Format(L("TenancyNameIsAlreadyTaken"), tenant.TenancyName));
                }

                await TenantRepository.UpdateAsync(tenant);
            });
        }

        public virtual void Update(TTenant tenant)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                if (TenantRepository.FirstOrDefault(t => t.TenancyName == tenant.TenancyName && t.Id != tenant.Id) != null)
                {
                    throw new UserFriendlyException(string.Format(L("TenancyNameIsAlreadyTaken"), tenant.TenancyName));
                }

                TenantRepository.Update(tenant);
            });
        }

        public virtual async Task<TTenant> FindByIdAsync(string id)
        {
            return await UnitOfWorkManager.WithUnitOfWorkAsync(async () => await TenantRepository.FirstOrDefaultAsync(id));
        }

        public virtual TTenant FindById(string id)
        {
            return UnitOfWorkManager.WithUnitOfWork(() => TenantRepository.FirstOrDefault(id));
        }

        public virtual async Task<TTenant> GetByIdAsync(string id)
        {
            var tenant = await FindByIdAsync(id);
            if (tenant == null)
            {
                throw new AbpException("There is no tenant with id: " + id);
            }

            return tenant;
        }

        public virtual TTenant GetById(string id)
        {
            var tenant = FindById(id);
            if (tenant == null)
            {
                throw new AbpException("There is no tenant with id: " + id);
            }

            return tenant;
        }

        public virtual async Task<TTenant> FindByTenancyNameAsync(string tenancyName)
        {
            return await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                return await TenantRepository.FirstOrDefaultAsync(t => t.TenancyName == tenancyName);
            });
        }

        public virtual TTenant FindByTenancyName(string tenancyName)
        {
            return UnitOfWorkManager.WithUnitOfWork(() =>
            {
                return TenantRepository.FirstOrDefault(t => t.TenancyName == tenancyName);
            });
        }

        public virtual async Task DeleteAsync(TTenant tenant)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await TenantRepository.DeleteAsync(tenant);
            });
        }

        public virtual void Delete(TTenant tenant)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                TenantRepository.Delete(tenant);
            });
        }

        public Task<string> GetFeatureValueOrNullAsync(string tenantId, string featureName)
        {
            return _featureValueStore.GetValueOrNullAsync(tenantId, featureName);
        }

        public string GetFeatureValueOrNull(string tenantId, string featureName)
        {
            return _featureValueStore.GetValueOrNull(tenantId, featureName);
        }

        public virtual async Task<IReadOnlyList<NameValue>> GetFeatureValuesAsync(string tenantId)
        {
            var values = new List<NameValue>();

            foreach (var feature in FeatureManager.GetAll())
            {
                values.Add(new NameValue(feature.Name, await GetFeatureValueOrNullAsync(tenantId, feature.Name) ?? feature.DefaultValue));
            }

            return values;
        }

        public virtual IReadOnlyList<NameValue> GetFeatureValues(string tenantId)
        {
            var values = new List<NameValue>();

            foreach (var feature in FeatureManager.GetAll())
            {
                values.Add(new NameValue(feature.Name, GetFeatureValueOrNull(tenantId, feature.Name) ?? feature.DefaultValue));
            }

            return values;
        }

        public virtual async Task SetFeatureValuesAsync(string tenantId, params NameValue[] values)
        {
            if (values.IsNullOrEmpty())
            {
                return;
            }

            foreach (var value in values)
            {
                await SetFeatureValueAsync(tenantId, value.Name, value.Value);
            }
        }

        public virtual void SetFeatureValues(string tenantId, params NameValue[] values)
        {
            if (values.IsNullOrEmpty())
            {
                return;
            }

            foreach (var value in values)
            {
                SetFeatureValue(tenantId, value.Name, value.Value);
            }
        }

        public virtual async Task SetFeatureValueAsync(string tenantId, string featureName, string value)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await SetFeatureValueAsync(await GetByIdAsync(tenantId), featureName, value);
            });
        }

        public virtual void SetFeatureValue(string tenantId, string featureName, string value)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                SetFeatureValue(GetById(tenantId), featureName, value);
            });
        }

        public virtual async Task SetFeatureValueAsync(TTenant tenant, string featureName, string value)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                //No need to change if it's already equals to the current value
                if (await GetFeatureValueOrNullAsync(tenant.Id, featureName) == value)
                {
                    return;
                }

                //Get the current feature setting
                TenantFeatureSetting currentSetting;
                using (UnitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (UnitOfWorkManager.Current.SetTenantId(tenant.Id))
                {
                    currentSetting = await TenantFeatureRepository.FirstOrDefaultAsync(f => f.Name == featureName);
                }

                //Get the feature
                var feature = FeatureManager.GetOrNull(featureName);
                if (feature == null)
                {
                    if (currentSetting != null)
                    {
                        await TenantFeatureRepository.DeleteAsync(currentSetting);
                    }
                    
                    return;
                }

                //Determine default value
                var defaultValue = tenant.EditionId.HasValue()
                    ? (await EditionManager.GetFeatureValueOrNullAsync(tenant.EditionId, featureName) ?? feature.DefaultValue)
                    : feature.DefaultValue;

                //No need to store value if it's default
                if (value == defaultValue)
                {
                    if (currentSetting != null)
                    {
                        await TenantFeatureRepository.DeleteAsync(currentSetting);
                    }
                    
                    return;
                }

                //Insert/update the feature value
                if (currentSetting == null)
                {
                    await TenantFeatureRepository.InsertAsync(new TenantFeatureSetting(tenant.Id, featureName, value));
                }
                else
                {
                    currentSetting.Value = value;
                }
            });
        }

        public virtual void SetFeatureValue(TTenant tenant, string featureName, string value)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                 //No need to change if it's already equals to the current value
                if (GetFeatureValueOrNull(tenant.Id, featureName) == value)
                {
                    return;
                }

                //Get the current feature setting
                TenantFeatureSetting currentSetting;
                using (UnitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (UnitOfWorkManager.Current.SetTenantId(tenant.Id))
                {
                    currentSetting = TenantFeatureRepository.FirstOrDefault(f => f.Name == featureName);
                }

                //Get the feature
                var feature = FeatureManager.GetOrNull(featureName);
                if (feature == null)
                {
                    if (currentSetting != null)
                    {
                        TenantFeatureRepository.Delete(currentSetting);
                    }

                    return;
                }

                //Determine default value
                var defaultValue = tenant.EditionId.HasValue()
                    ? (EditionManager.GetFeatureValueOrNull(tenant.EditionId, featureName) ?? feature.DefaultValue)
                    : feature.DefaultValue;

                //No need to store value if it's default
                if (value == defaultValue)
                {
                    if (currentSetting != null)
                    {
                        TenantFeatureRepository.Delete(currentSetting);
                    }

                    return;
                }

                //Insert/update the feature value
                if (currentSetting == null)
                {
                    TenantFeatureRepository.Insert(new TenantFeatureSetting(tenant.Id, featureName, value));
                }
                else
                {
                    currentSetting.Value = value;
                }
            });
        }

        /// <summary>
        /// Resets all custom feature settings for a tenant.
        /// Tenant will have features according to it's edition.
        /// </summary>
        /// <param name="tenantId">Tenant Id</param>
        public virtual async Task ResetAllFeaturesAsync(string tenantId)
        {
            await UnitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                using (UnitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (UnitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    await TenantFeatureRepository.DeleteAsync(f => f.TenantId == tenantId);
                }
            });
        }

        /// <summary>
        /// Resets all custom feature settings for a tenant.
        /// Tenant will have features according to it's edition.
        /// </summary>
        /// <param name="tenantId">Tenant Id</param>
        public virtual void ResetAllFeatures(string tenantId)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                using (UnitOfWorkManager.Current.EnableFilter(AbpDataFilters.MayHaveTenant))
                using (UnitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    TenantFeatureRepository.Delete(f => f.TenantId == tenantId);
                }
            });
        }

        protected virtual async Task ValidateTenantAsync(TTenant tenant)
        {
            await ValidateTenancyNameAsync(tenant.TenancyName);
        }

        protected virtual void ValidateTenant(TTenant tenant)
        {
            ValidateTenancyName(tenant.TenancyName);
        }

        protected virtual Task ValidateTenancyNameAsync(string tenancyName)
        {
            if (!Regex.IsMatch(tenancyName, AbpTenant<TUser>.TenancyNameRegex))
            {
                throw new UserFriendlyException(L("InvalidTenancyName"));
            }

            return Task.FromResult(0);
        }

        protected virtual void ValidateTenancyName(string tenancyName)
        {
            if (!Regex.IsMatch(tenancyName, AbpTenant<TUser>.TenancyNameRegex))
            {
                throw new UserFriendlyException(L("InvalidTenancyName"));
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

        public void HandleEvent(EntityChangedEventData<TTenant> eventData)
        {
            if (eventData.Entity.IsTransient())
            {
                return;
            }

            CacheManager.GetTenantFeatureCache().Remove(eventData.Entity.Id);
        }
        
        public virtual void HandleEvent(EntityDeletedEventData<Edition> eventData)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                var relatedTenants = TenantRepository.GetAllList(t => t.EditionId == eventData.Entity.Id);
                foreach (var relatedTenant in relatedTenants)
                {
                    relatedTenant.EditionId = null;
                }
            });
        }
    }
}
