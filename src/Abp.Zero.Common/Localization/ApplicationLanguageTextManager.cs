using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.Domain.Uow;
using Abp.Extensions;

namespace Abp.Localization
{
    /// <summary>
    /// Manages localization texts for host and tenants.
    /// </summary>
    public class ApplicationLanguageTextManager : IApplicationLanguageTextManager, ITransientDependency
    {
        private readonly ILocalizationManager _localizationManager;
        private readonly IRepository<ApplicationLanguageText, string> _applicationTextRepository;
        private readonly IUnitOfWorkManager _unitOfWorkManager;

        /// <summary>
        /// Initializes a new instance of the <see cref="ApplicationLanguageTextManager"/> class.
        /// </summary>
        public ApplicationLanguageTextManager(
            ILocalizationManager localizationManager,
            IRepository<ApplicationLanguageText, string> applicationTextRepository,
            IUnitOfWorkManager unitOfWorkManager)
        {
            _localizationManager = localizationManager;
            _applicationTextRepository = applicationTextRepository;
            _unitOfWorkManager = unitOfWorkManager;
        }

        /// <summary>
        /// Gets a localized string value.
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        /// <param name="sourceName">Source name</param>
        /// <param name="culture">Culture</param>
        /// <param name="key">Localization key</param>
        /// <param name="tryDefaults">True: fallbacks to default languages if can not find in given culture</param>
        public string GetStringOrNull(string tenantId, string sourceName, CultureInfo culture, string key, bool tryDefaults = true)
        {
            var source = _localizationManager.GetSource(sourceName);

            if (!(source is IMultiTenantLocalizationSource))
            {
                return source.GetStringOrNull(key, culture, tryDefaults);
            }

            return source
                .As<IMultiTenantLocalizationSource>()
                .GetStringOrNull(tenantId, key, culture, tryDefaults);
        }

        public List<string> GetStringsOrNull(string tenantId, string sourceName, CultureInfo culture, List<string> keys, bool tryDefaults = true)
        {
            var source = _localizationManager.GetSource(sourceName);

            if (!(source is IMultiTenantLocalizationSource))
            {
                return source.GetStringsOrNull(keys, culture, tryDefaults);
            }

            return source
                .As<IMultiTenantLocalizationSource>()
                .GetStringsOrNull(tenantId, keys, culture, tryDefaults);
        }

        /// <summary>
        /// Updates a localized string value.
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        /// <param name="sourceName">Source name</param>
        /// <param name="culture">Culture</param>
        /// <param name="key">Localization key</param>
        /// <param name="value">New localized value.</param>
        public virtual async Task UpdateStringAsync(string tenantId, string sourceName, CultureInfo culture, string key, string value)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    var existingEntity = (await _applicationTextRepository.GetAllListAsync(t =>
                            t.Source == sourceName &&
                            t.LanguageName == culture.Name &&
                            t.Key == key))
                        .FirstOrDefault(t => t.Key == key);

                    if (existingEntity != null)
                    {
                        if (existingEntity.Value != value)
                        {
                            existingEntity.Value = value;
                            await _unitOfWorkManager.Current.SaveChangesAsync();
                        }
                    }
                    else
                    {
                        await _applicationTextRepository.InsertAsync(
                            new ApplicationLanguageText
                            {
                                TenantId = tenantId,
                                Source = sourceName,
                                LanguageName = culture.Name,
                                Key = key,
                                Value = value
                            });
                        await _unitOfWorkManager.Current.SaveChangesAsync();
                    }
                }
            });
        }
    }
}
