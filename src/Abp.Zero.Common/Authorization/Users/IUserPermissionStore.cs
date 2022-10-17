using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.Authorization.Users
{
    /// <summary>
    /// Used to perform permission database operations for a user.
    /// </summary>
    public interface IUserPermissionStore<in TUser>
        where TUser : AbpUserBase
    {
        /// <summary>
        /// Adds a permission grant setting to a user.
        /// </summary>
        /// <param name="user">User</param>
        /// <param name="permissionGrant">Permission grant setting info</param>
        Task AddPermissionAsync(TUser user, PermissionGrantInfo permissionGrant);

        /// <summary>
        /// Adds a permission grant setting to a user.
        /// </summary>
        /// <param name="user">User</param>
        /// <param name="permissionGrant">Permission grant setting info</param>
        void AddPermission(TUser user, PermissionGrantInfo permissionGrant);

        /// <summary>
        /// Removes a permission grant setting from a user.
        /// </summary>
        /// <param name="user">User</param>
        /// <param name="permissionGrant">Permission grant setting info</param>
        Task RemovePermissionAsync(TUser user, PermissionGrantInfo permissionGrant);

        /// <summary>
        /// Removes a permission grant setting from a user.
        /// </summary>
        /// <param name="user">User</param>
        /// <param name="permissionGrant">Permission grant setting info</param>
        void RemovePermission(TUser user, PermissionGrantInfo permissionGrant);

        /// <summary>
        /// Gets permission grant setting informations for a user.
        /// </summary>
        /// <param name="userId">User id</param>
        /// <returns>List of permission setting informations</returns>
        Task<IList<PermissionGrantInfo>> GetPermissionsAsync(string userId);

        /// <summary>
        /// Gets permission grant setting informations for a user.
        /// </summary>
        /// <param name="userId">User id</param>
        /// <returns>List of permission setting informations</returns>
        IList<PermissionGrantInfo> GetPermissions(string userId);

        /// <summary>
        /// Checks whether a role has a permission grant setting info.
        /// </summary>
        /// <param name="userId">User id</param>
        /// <param name="permissionGrant">Permission grant setting info</param>
        /// <returns></returns>
        Task<bool> HasPermissionAsync(string userId, PermissionGrantInfo permissionGrant);

        /// <summary>
        /// Checks whether a role has a permission grant setting info.
        /// </summary>
        /// <param name="userId">User id</param>
        /// <param name="permissionGrant">Permission grant setting info</param>
        /// <returns></returns>
        bool HasPermission(string userId, PermissionGrantInfo permissionGrant);

        /// <summary>
        /// Deleted all permission settings for a role.
        /// </summary>
        /// <param name="user">User</param>
        Task RemoveAllPermissionSettingsAsync(TUser user);

        /// <summary>
        /// Deleted all permission settings for a role.
        /// </summary>
        /// <param name="user">User</param>
        void RemoveAllPermissionSettings(TUser user);
    }
}
