using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using System.Threading.Tasks;
using Abp.Configuration;
using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.Domain.Uow;
using Abp.Events.Bus.Entities;
using Abp.Events.Bus.Handlers;
using Abp.Runtime.Caching;
using System.Globalization;

namespace Abp.Localization
{
    /// <summary>
    /// Manages host and tenant languages.
    /// </summary>
    public class ApplicationLanguageManager :
        IApplicationLanguageManager,
        IEventHandler<EntityChangedEventData<ApplicationLanguage>>,
        ISingletonDependency
    {
        /// <summary>
        /// Cache name for languages.
        /// </summary>
        public const string CacheName = "AbpZeroLanguages";

        private ITypedCache<string, Dictionary<string, ApplicationLanguage>> LanguageListCache =>
            _cacheManager.GetCache<string, Dictionary<string, ApplicationLanguage>>(CacheName);

        private readonly IRepository<ApplicationLanguage> _languageRepository;
        private readonly ICacheManager _cacheManager;
        private readonly IUnitOfWorkManager _unitOfWorkManager;
        private readonly ISettingManager _settingManager;

        /// <summary>
        /// Initializes a new instance of the <see cref="ApplicationLanguageManager"/> class.
        /// </summary>
        public ApplicationLanguageManager(
            IRepository<ApplicationLanguage> languageRepository,
            ICacheManager cacheManager,
            IUnitOfWorkManager unitOfWorkManager,
            ISettingManager settingManager)
        {
            _languageRepository = languageRepository;
            _cacheManager = cacheManager;
            _unitOfWorkManager = unitOfWorkManager;
            _settingManager = settingManager;
        }

        /// <summary>
        /// Gets list of all languages available to given tenant (or null for host)
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        public virtual async Task<IReadOnlyList<ApplicationLanguage>> GetLanguagesAsync(string tenantId)
        {
            return (await GetLanguageDictionaryAsync(tenantId)).Values.ToImmutableList();
        }

        public virtual async Task<IReadOnlyList<ApplicationLanguage>> GetActiveLanguagesAsync(string tenantId)
        {
            return (await GetLanguagesAsync(tenantId)).Where(l => !l.IsDisabled).ToImmutableList();
        }

        /// <summary>
        /// Gets list of all languages available to given tenant (or null for host)
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        public virtual IReadOnlyList<ApplicationLanguage> GetLanguages(string tenantId)
        {
            return (GetLanguageDictionary(tenantId)).Values.ToImmutableList();
        }

        public virtual IReadOnlyList<ApplicationLanguage> GetActiveLanguages(string tenantId)
        {
            return GetLanguages(tenantId).Where(l => !l.IsDisabled).ToImmutableList();
        }

        /// <summary>
        /// Adds a new language.
        /// </summary>
        /// <param name="language">The language.</param>
        public virtual async Task AddAsync(ApplicationLanguage language)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                if ((await GetLanguagesAsync(language.TenantId)).Any(l => l.Name == language.Name))
                {
                    throw new AbpException("There is already a language with name = " + language.Name);
                }

                using (_unitOfWorkManager.Current.SetTenantId(language.TenantId))
                {
                    await _languageRepository.InsertAsync(language);
                    await _unitOfWorkManager.Current.SaveChangesAsync();
                }
            });
        }

        /// <summary>
        /// Adds a new language.
        /// </summary>
        /// <param name="language">The language.</param>
        public virtual void Add(ApplicationLanguage language)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                if ((GetLanguages(language.TenantId)).Any(l => l.Name == language.Name))
                {
                    throw new AbpException("There is already a language with name = " + language.Name);
                }

                using (_unitOfWorkManager.Current.SetTenantId(language.TenantId))
                {
                    _languageRepository.Insert(language);
                    _unitOfWorkManager.Current.SaveChanges();
                }
            });
        }

        /// <summary>
        /// Deletes a language.
        /// </summary>
        /// <param name="tenantId">Tenant Id or null for host.</param>
        /// <param name="languageName">Name of the language.</param>
        public virtual async Task RemoveAsync(string tenantId, string languageName)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                var currentLanguage = (await GetLanguagesAsync(tenantId)).FirstOrDefault(l => l.Name == languageName);
                if (currentLanguage == null)
                {
                    return;
                }

                if (currentLanguage.TenantId == null && tenantId != null)
                {
                    throw new AbpException("Can not delete a host language from tenant!");
                }

                using (_unitOfWorkManager.Current.SetTenantId(currentLanguage.TenantId))
                {
                    await _languageRepository.DeleteAsync(currentLanguage.Id);
                    await _unitOfWorkManager.Current.SaveChangesAsync();
                }
            });
        }

        /// <summary>
        /// Deletes a language.
        /// </summary>
        /// <param name="tenantId">Tenant Id or null for host.</param>
        /// <param name="languageName">Name of the language.</param>
        public virtual void Remove(string tenantId, string languageName)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                var currentLanguage = (GetLanguages(tenantId)).FirstOrDefault(l => l.Name == languageName);
                if (currentLanguage == null)
                {
                    return;
                }

                if (currentLanguage.TenantId == null && tenantId != null)
                {
                    throw new AbpException("Can not delete a host language from tenant!");
                }

                using (_unitOfWorkManager.Current.SetTenantId(currentLanguage.TenantId))
                {
                    _languageRepository.Delete(currentLanguage.Id);
                    _unitOfWorkManager.Current.SaveChanges();
                }
            });
        }

        /// <summary>
        /// Updates a language.
        /// </summary>
        public virtual async Task UpdateAsync(string tenantId, ApplicationLanguage language)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                var existingLanguageWithSameName =
                    (await GetLanguagesAsync(language.TenantId)).FirstOrDefault(l => l.Name == language.Name);
                if (existingLanguageWithSameName != null)
                {
                    if (existingLanguageWithSameName.Id != language.Id)
                    {
                        throw new AbpException("There is already a language with name = " + language.Name);
                    }
                }

                if (language.TenantId == null && tenantId != null)
                {
                    throw new AbpException("Can not update a host language from tenant");
                }

                using (_unitOfWorkManager.Current.SetTenantId(language.TenantId))
                {
                    await _languageRepository.UpdateAsync(language);
                    await _unitOfWorkManager.Current.SaveChangesAsync();
                }
            });
        }

        /// <summary>
        /// Updates a language.
        /// </summary>
        public virtual void Update(string tenantId, ApplicationLanguage language)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                var existingLanguageWithSameName =
                    (GetLanguages(language.TenantId)).FirstOrDefault(l => l.Name == language.Name);
                if (existingLanguageWithSameName != null)
                {
                    if (existingLanguageWithSameName.Id != language.Id)
                    {
                        throw new AbpException("There is already a language with name = " + language.Name);
                    }
                }

                if (language.TenantId == null && tenantId != null)
                {
                    throw new AbpException("Can not update a host language from tenant");
                }

                using (_unitOfWorkManager.Current.SetTenantId(language.TenantId))
                {
                    _languageRepository.Update(language);
                    _unitOfWorkManager.Current.SaveChanges();
                }
            });
        }

        /// <summary>
        /// Gets the default language or null for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        public virtual async Task<ApplicationLanguage> GetDefaultLanguageOrNullAsync(string tenantId)
        {
            var defaultLanguageName = tenantId.HasValue()
                ? await _settingManager.GetSettingValueForTenantAsync(LocalizationSettingNames.DefaultLanguage,
                    tenantId)
                : await _settingManager.GetSettingValueForApplicationAsync(LocalizationSettingNames.DefaultLanguage);

            return (await GetLanguagesAsync(tenantId)).FirstOrDefault(l => l.Name == defaultLanguageName);
        }

        /// <summary>
        /// Gets the default language or null for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        public virtual ApplicationLanguage GetDefaultLanguageOrNull(string tenantId)
        {
            var defaultLanguageName = tenantId.HasValue()
                ? _settingManager.GetSettingValueForTenant(LocalizationSettingNames.DefaultLanguage, tenantId)
                : _settingManager.GetSettingValueForApplication(LocalizationSettingNames.DefaultLanguage);

            return (GetLanguages(tenantId)).FirstOrDefault(l => l.Name == defaultLanguageName);
        }

        /// <summary>
        /// Sets the default language for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        /// <param name="languageName">Name of the language.</param>
        public virtual async Task SetDefaultLanguageAsync(string tenantId, string languageName)
        {
            var cultureInfo = CultureInfo.GetCultureInfo(languageName);
            if (tenantId.HasValue())
            {
                await _settingManager.ChangeSettingForTenantAsync(tenantId,
                    LocalizationSettingNames.DefaultLanguage, cultureInfo.Name);
            }
            else
            {
                await _settingManager.ChangeSettingForApplicationAsync(LocalizationSettingNames.DefaultLanguage,
                    cultureInfo.Name);
            }
        }

        /// <summary>
        /// Sets the default language for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        /// <param name="languageName">Name of the language.</param>
        public virtual void SetDefaultLanguage(string tenantId, string languageName)
        {
            var cultureInfo = CultureInfo.GetCultureInfo(languageName);
            if (tenantId.HasValue())
            {
                _settingManager.ChangeSettingForTenant(tenantId, LocalizationSettingNames.DefaultLanguage,
                    cultureInfo.Name);
            }
            else
            {
                _settingManager.ChangeSettingForApplication(LocalizationSettingNames.DefaultLanguage, cultureInfo.Name);
            }
        }

        public void HandleEvent(EntityChangedEventData<ApplicationLanguage> eventData)
        {
            LanguageListCache.Remove(eventData.Entity.TenantId ?? "0");

            //Also invalidate the language script cache
            _cacheManager.GetCache("AbpLocalizationScripts").Clear();
        }

        protected virtual async Task<Dictionary<string, ApplicationLanguage>> GetLanguageDictionaryAsync(string tenantId)
        {
            //Creates a copy of the cached dictionary (to not modify it)
            var languageDictionary =
                new Dictionary<string, ApplicationLanguage>(await GetLanguageDictionaryFromCacheAsync(null));

            if (tenantId == null)
            {
                return languageDictionary;
            }

            //Override tenant languages
            foreach (var tenantLanguage in await GetLanguageDictionaryFromCacheAsync(tenantId))
            {
                languageDictionary[tenantLanguage.Key] = tenantLanguage.Value;
            }

            return languageDictionary;
        }

        protected virtual Dictionary<string, ApplicationLanguage> GetLanguageDictionary(string tenantId)
        {
            //Creates a copy of the cached dictionary (to not modify it)
            var languageDictionary = new Dictionary<string, ApplicationLanguage>(GetLanguageDictionaryFromCache(null));

            if (tenantId == null)
            {
                return languageDictionary;
            }

            //Override tenant languages
            foreach (var tenantLanguage in GetLanguageDictionaryFromCache(tenantId))
            {
                languageDictionary[tenantLanguage.Key] = tenantLanguage.Value;
            }

            return languageDictionary;
        }

        private Task<Dictionary<string, ApplicationLanguage>> GetLanguageDictionaryFromCacheAsync(string tenantId)
        {
            return LanguageListCache.GetAsync(tenantId ?? "0", () => GetLanguagesFromDatabaseAsync(tenantId));
        }

        private Dictionary<string, ApplicationLanguage> GetLanguageDictionaryFromCache(string tenantId)
        {
            return LanguageListCache.Get(tenantId ?? "0", () => GetLanguagesFromDatabase(tenantId));
        }

        protected virtual async Task<Dictionary<string, ApplicationLanguage>> GetLanguagesFromDatabaseAsync(
            string tenantId)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    return (await _languageRepository.GetAllListAsync()).ToDictionary(l => l.Name);
                }
            });
        }

        protected virtual Dictionary<string, ApplicationLanguage> GetLanguagesFromDatabase(string tenantId)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    return (_languageRepository.GetAllList()).ToDictionary(l => l.Name);
                }
            });
        }
    }
}
