using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.Localization
{
    /// <summary>
    /// Manages host and tenant languages.
    /// </summary>
    public interface IApplicationLanguageManager
    {
        /// <summary>
        /// Gets list of all languages available to given tenant (or null for host)
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        Task<IReadOnlyList<ApplicationLanguage>> GetLanguagesAsync(string tenantId);

        /// <summary>
        /// Gets list of all active languages available to given tenant (or null for host)
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        Task<IReadOnlyList<ApplicationLanguage>> GetActiveLanguagesAsync(string tenantId);

        /// <summary>
        /// Gets list of all languages available to given tenant (or null for host)
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        IReadOnlyList<ApplicationLanguage> GetLanguages(string tenantId);

        /// <summary>
        /// Gets list of all active languages available to given tenant (or null for host)
        /// </summary>
        /// <param name="tenantId">TenantId or null for host</param>
        IReadOnlyList<ApplicationLanguage> GetActiveLanguages(string tenantId);

        /// <summary>
        /// Adds a new language.
        /// </summary>
        /// <param name="language">The language.</param>
        Task AddAsync(ApplicationLanguage language);

        /// <summary>
        /// Adds a new language.
        /// </summary>
        /// <param name="language">The language.</param>
        void Add(ApplicationLanguage language);

        /// <summary>
        /// Deletes a language.
        /// </summary>
        /// <param name="tenantId">Tenant Id or null for host.</param>
        /// <param name="languageName">Name of the language.</param>
        Task RemoveAsync(string tenantId, string languageName);

        /// <summary>
        /// Deletes a language.
        /// </summary>
        /// <param name="tenantId">Tenant Id or null for host.</param>
        /// <param name="languageName">Name of the language.</param>
        void Remove(string tenantId, string languageName);

        /// <summary>
        /// Updates a language.
        /// </summary>
        /// <param name="tenantId">Tenant Id or null for host.</param>
        /// <param name="language">The language to be updated</param>
        Task UpdateAsync(string tenantId, ApplicationLanguage language);

        /// <summary>
        /// Updates a language.
        /// </summary>
        /// <param name="tenantId">Tenant Id or null for host.</param>
        /// <param name="language">The language to be updated</param>
        void Update(string tenantId, ApplicationLanguage language);

        /// <summary>
        /// Gets the default language or null for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        Task<ApplicationLanguage> GetDefaultLanguageOrNullAsync(string tenantId);

        /// <summary>
        /// Gets the default language or null for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        ApplicationLanguage GetDefaultLanguageOrNull(string tenantId);

        /// <summary>
        /// Sets the default language for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        /// <param name="languageName">Name of the language.</param>
        Task SetDefaultLanguageAsync(string tenantId, string languageName);

        /// <summary>
        /// Sets the default language for a tenant or the host.
        /// </summary>
        /// <param name="tenantId">Tenant Id of null for host</param>
        /// <param name="languageName">Name of the language.</param>
        void SetDefaultLanguage(string tenantId, string languageName);
    }
}
