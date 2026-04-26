using System.DirectoryServices.AccountManagement;
using System.Threading.Tasks;

namespace Abp.Zero.Ldap.Configuration
{
    /// <summary>
    /// Used to obtain current values of LDAP settings.
    /// This abstraction allows to define a different source for settings than SettingManager (see default implementation: <see cref="LdapSettings"/>).
    /// </summary>
    public interface ILdapSettings
    {
        Task<bool> GetIsEnabled(string tenantId);

        Task<ContextType> GetContextType(string tenantId);

        Task<string> GetContainer(string tenantId);

        Task<string> GetDomain(string tenantId);

        Task<string> GetUserName(string tenantId);

        Task<string> GetPassword(string tenantId);
        
        Task<bool> GetUseSsl(string tenantId);
    }
}
