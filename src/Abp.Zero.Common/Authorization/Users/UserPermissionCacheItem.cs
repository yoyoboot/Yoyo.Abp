using System;
using System.Collections.Generic;

namespace Abp.Authorization.Users
{
    /// <summary>
    /// Used to cache roles and permissions of a user.
    /// </summary>
    [Serializable]
    public class UserPermissionCacheItem
    {
        public const string CacheStoreName = "AbpZeroUserPermissions";

        public string UserId { get; set; }

        public List<string> RoleIds { get; set; }

        public HashSet<string> GrantedPermissions { get; set; }

        public HashSet<string> ProhibitedPermissions { get; set; }

        public UserPermissionCacheItem()
        {
            RoleIds = new List<string>();
            GrantedPermissions = new HashSet<string>();
            ProhibitedPermissions = new HashSet<string>();
        }

        public UserPermissionCacheItem(string userId)
            : this()
        {
            UserId = userId;
        }
    }
}
