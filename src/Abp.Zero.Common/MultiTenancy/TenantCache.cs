using System.Threading.Tasks;
using Abp.Authorization.Users;
using Abp.Domain.Repositories;
using Abp.Domain.Uow;
using Abp.Events.Bus.Entities;
using Abp.Events.Bus.Handlers;
using Abp.Runtime.Caching;
using Abp.Runtime.Security;

namespace Abp.MultiTenancy
{
    public class TenantCache<TTenant, TUser> : ITenantCache, IEventHandler<EntityChangedEventData<TTenant>>
        where TTenant : AbpTenant<TUser>
        where TUser : AbpUserBase
    {
        private readonly ICacheManager _cacheManager;
        private readonly IRepository<TTenant> _tenantRepository;
        private readonly IUnitOfWorkManager _unitOfWorkManager;

        public TenantCache(
            ICacheManager cacheManager,
            IRepository<TTenant> tenantRepository,
            IUnitOfWorkManager unitOfWorkManager)
        {
            _cacheManager = cacheManager;
            _tenantRepository = tenantRepository;
            _unitOfWorkManager = unitOfWorkManager;
        }

        public virtual TenantCacheItem Get(string tenantId,int? fsTagNone=null)
        {
            var cacheItem = GetOrNull(tenantId,null);

            if (cacheItem == null)
            {
                throw new AbpException("There is no tenant with given id: " + tenantId);
            }

            return cacheItem;
        }

        public virtual TenantCacheItem Get(string tenancyName)
        {
            var cacheItem = GetOrNull(tenancyName);

            if (cacheItem == null)
            {
                throw new AbpException("There is no tenant with given tenancy name: " + tenancyName);
            }

            return cacheItem;
        }

        public virtual TenantCacheItem GetOrNull(string tenancyName)
        {
            var tenantId = _cacheManager
                .GetTenantByNameCache()
                .Get(
                    tenancyName.ToLowerInvariant(),
                    () => GetTenantOrNull(tenancyName)?.Id
                );

            if (tenantId == null)
            {
                return null;
            }

            return Get(tenantId,null);
        }

        public TenantCacheItem GetOrNull(string tenantId,int? fsTagNone=null)
        {
            return _cacheManager
                .GetTenantCache()
                .Get(
                    tenantId,
                    () =>
                    {
                        var tenant = GetTenantOrNull(tenantId,null);
                        if (tenant == null)
                        {
                            return null;
                        }

                        return CreateTenantCacheItem(tenant);
                    }
                );
        }

        public virtual async Task<TenantCacheItem> GetAsync(string tenantId,int? fsTagNone=null)
        {
            var cacheItem = await GetOrNullAsync(tenantId,null);

            if (cacheItem == null)
            {
                throw new AbpException("There is no tenant with given id: " + tenantId);
            }

            return cacheItem;
        }

        public virtual async Task<TenantCacheItem> GetAsync(string tenancyName)
        {
            var cacheItem = await GetOrNullAsync(tenancyName);

            if (cacheItem == null)
            {
                throw new AbpException("There is no tenant with given tenancy name: " + tenancyName);
            }

            return cacheItem;
        }

        public virtual async Task<TenantCacheItem> GetOrNullAsync(string tenancyName)
        {
            var tenantId = await _cacheManager
                .GetTenantByNameCache()
                .GetAsync(
                    tenancyName.ToLowerInvariant(), async key => (await GetTenantOrNullAsync(tenancyName))?.Id
                );

            if (tenantId == null)
            {
                return null;
            }

            return await GetAsync(tenantId,null);
        }

        public virtual async Task<TenantCacheItem> GetOrNullAsync(string tenantId,int? fsTagNone=null)
        {
            return await _cacheManager
                .GetTenantCache()
                .GetAsync(
                    tenantId, async key =>
                    {
                        var tenant = await GetTenantOrNullAsync(tenantId,null);
                        if (tenant == null)
                        {
                            return null;
                        }

                        return CreateTenantCacheItem(tenant);
                    }
                );
        }

        protected virtual TenantCacheItem CreateTenantCacheItem(TTenant tenant)
        {
            return new TenantCacheItem
            {
                Id = tenant.Id,
                Name = tenant.Name,
                TenancyName = tenant.TenancyName,
                EditionId = tenant.EditionId,
                ConnectionString = SimpleStringCipher.Instance.Decrypt(tenant.ConnectionString),
                IsActive = tenant.IsActive
            };
        }

        protected virtual TTenant GetTenantOrNull(string tenantId,int? fsTagNone=null)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    return _tenantRepository.FirstOrDefault(tenantId);
                }
            });
        }

        protected virtual TTenant GetTenantOrNull(string tenancyName)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    return _tenantRepository.FirstOrDefault(t => t.TenancyName == tenancyName);
                }
            });
        }

        protected virtual async Task<TTenant> GetTenantOrNullAsync(string tenantId,int? fsTagNone=null)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    return await _tenantRepository.FirstOrDefaultAsync(tenantId);
                }
            });
        }

        protected virtual async Task<TTenant> GetTenantOrNullAsync(string tenancyName)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(null))
                {
                    return await _tenantRepository.FirstOrDefaultAsync(t => t.TenancyName == tenancyName);
                }
            });
        }

        public virtual void HandleEvent(EntityChangedEventData<TTenant> eventData)
        {
            var existingCacheItem = _cacheManager.GetTenantCache().GetOrDefault(eventData.Entity.Id);

            _cacheManager
                .GetTenantByNameCache()
                .Remove(
                    existingCacheItem != null
                        ? existingCacheItem.TenancyName.ToLowerInvariant()
                        : eventData.Entity.TenancyName.ToLowerInvariant()
                );

            _cacheManager
                .GetTenantCache()
                .Remove(eventData.Entity.Id);
        }
    }
}
