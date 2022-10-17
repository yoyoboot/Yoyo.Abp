using System.Threading.Tasks;

namespace Abp.CachedUniqueKeys
{
    public interface ICachedUniqueKeyPerUser
    {
        Task<string> GetKeyAsync(string cacheName);

        Task RemoveKeyAsync(string cacheName);
        
        Task<string> GetKeyAsync(string cacheName, UserIdentifier user);

        Task RemoveKeyAsync(string cacheName, UserIdentifier user);

        Task<string> GetKeyAsync(string cacheName, string tenantId, string userId);

        Task RemoveKeyAsync(string cacheName, string tenantId, string userId);

        Task ClearCacheAsync(string cacheName);

        string GetKey(string cacheName);

        void RemoveKey(string cacheName);
        
        string GetKey(string cacheName, UserIdentifier user);

        void RemoveKey(string cacheName, UserIdentifier user);

        string GetKey(string cacheName, string tenantId, string userId);

        void RemoveKey(string cacheName, string tenantId, string userId);

        void ClearCache(string cacheName);
    }
}
