using System.DirectoryServices.AccountManagement;
using System.Threading.Tasks;
using Abp.Configuration;
using Abp.Dependency;
using Abp.Extensions;

namespace Abp.Zero.Ldap.Configuration
{
    /// <summary>
    /// Implements <see cref="ILdapSettings"/> to get settings from <see cref="ISettingManager"/>.
    /// </summary>
    
    public class LdapSettings : ILdapSettings, ITransientDependency
    {
        protected ISettingManager SettingManager { get; }

        public LdapSettings(ISettingManager settingManager)
        {
            SettingManager = settingManager;
        }

        public virtual Task<bool> GetIsEnabled(string tenantId)
        {
            return tenantId.HasValue()
                ? SettingManager.GetSettingValueForTenantAsync<bool>(LdapSettingNames.IsEnabled, tenantId)
                : SettingManager.GetSettingValueForApplicationAsync<bool>(LdapSettingNames.IsEnabled);
        }

        public virtual async Task<ContextType> GetContextType(string tenantId)
        {
            return tenantId.HasValue()
                ? (await SettingManager.GetSettingValueForTenantAsync(LdapSettingNames.ContextType, tenantId)).ToEnum<ContextType>()
                : (await SettingManager.GetSettingValueForApplicationAsync(LdapSettingNames.ContextType)).ToEnum<ContextType>();
        }

        public virtual Task<string> GetContainer(string tenantId)
        {
            return tenantId.HasValue()
                ? SettingManager.GetSettingValueForTenantAsync(LdapSettingNames.Container, tenantId)
                : SettingManager.GetSettingValueForApplicationAsync(LdapSettingNames.Container);
        }

        public virtual Task<string> GetDomain(string tenantId)
        {
            return tenantId.HasValue()
                ? SettingManager.GetSettingValueForTenantAsync(LdapSettingNames.Domain, tenantId)
                : SettingManager.GetSettingValueForApplicationAsync(LdapSettingNames.Domain);
        }

        public virtual Task<string> GetUserName(string tenantId)
        {
            return tenantId.HasValue()
                ? SettingManager.GetSettingValueForTenantAsync(LdapSettingNames.UserName, tenantId)
                : SettingManager.GetSettingValueForApplicationAsync(LdapSettingNames.UserName);
        }

        public virtual Task<string> GetPassword(string tenantId)
        {
            return tenantId.HasValue()
                ? SettingManager.GetSettingValueForTenantAsync(LdapSettingNames.Password, tenantId)
                : SettingManager.GetSettingValueForApplicationAsync(LdapSettingNames.Password);
        }
    }
}
