using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Abp.Authorization.Roles;
using Abp.Organizations;
using Microsoft.AspNetCore.Identity;

namespace Abp.Authorization.Users;

public interface IAbpUserManager<TRole, TUser>
    where TRole : AbpRole<TUser>, new()
    where TUser : AbpUser<TUser>
{
    Task<IQueryable<TUser>> GetUsersAsync();
    Task<bool> IsGrantedAsync(string userId, string permissionName);
    bool IsGranted(string userId, string permissionName);
    Task<bool> IsGrantedAsync(TUser user, Permission permission);
    bool IsGranted(TUser user, Permission permission);
    Task<bool> IsGrantedAsync(string userId, Permission permission);
    bool IsGranted(string userId, Permission permission);
    Task<IReadOnlyList<Permission>> GetGrantedPermissionsAsync(TUser user);
    Task SetGrantedPermissionsAsync(TUser user, IEnumerable<Permission> permissions);
    Task ProhibitAllPermissionsAsync(TUser user);
    Task ResetAllPermissionsAsync(TUser user);
    void ResetAllPermissions(TUser user);
    Task GrantPermissionAsync(TUser user, Permission permission);
    Task ProhibitPermissionAsync(TUser user, Permission permission);
    Task<TUser> FindByNameOrEmailAsync(string userNameOrEmailAddress);
    TUser FindByNameOrEmail(string userNameOrEmailAddress);
    Task<List<TUser>> FindAllAsync(UserLoginInfo login);
    List<TUser> FindAll(UserLoginInfo login);
    Task<TUser> FindAsync(string tenantId, UserLoginInfo login);
    TUser Find(string tenantId, UserLoginInfo login);
    Task<TUser> FindByNameOrEmailAsync(string tenantId, string userNameOrEmailAddress);
    TUser FindByNameOrEmail(string tenantId, string userNameOrEmailAddress);
    Task<TUser> GetUserByIdAsync(string userId);
    TUser GetUserById(string userId);
    Task<IdentityResult> ChangePasswordAsync(TUser user, string newPassword);
    Task<IdentityResult> CheckDuplicateUsernameOrEmailAddressAsync(string expectedUserId, string userName, string emailAddress);
    Task<IdentityResult> SetRolesAsync(TUser user, string[] roleNames);
    Task<bool> IsInOrganizationUnitAsync(string userId, string ouId);
    Task<bool> IsInOrganizationUnitAsync(TUser user, OrganizationUnit ou);
    bool IsInOrganizationUnit(TUser user, OrganizationUnit ou);
    Task AddToOrganizationUnitAsync(string userId, string ouId);
    Task AddToOrganizationUnitAsync(TUser user, OrganizationUnit ou);
    void AddToOrganizationUnit(TUser user, OrganizationUnit ou);
    Task RemoveFromOrganizationUnitAsync(string userId, string ouId);
    Task RemoveFromOrganizationUnitAsync(TUser user, OrganizationUnit ou);
    void RemoveFromOrganizationUnit(TUser user, OrganizationUnit ou);
    Task SetOrganizationUnitsAsync(string userId, params string[] organizationUnitIds);
    Task SetOrganizationUnitsAsync(TUser user, params string[] organizationUnitIds);
    void SetOrganizationUnits(TUser user, params string[] organizationUnitIds);
    Task<List<OrganizationUnit>> GetOrganizationUnitsAsync(TUser user);
    List<OrganizationUnit> GetOrganizationUnits(TUser user);
    Task<List<TUser>> GetUsersInOrganizationUnitAsync(OrganizationUnit organizationUnit, bool includeChildren = false);
    List<TUser> GetUsersInOrganizationUnit(OrganizationUnit organizationUnit, bool includeChildren = false);
    Task InitializeOptionsAsync(string tenantId);
    void InitializeOptions(string tenantId);
    Task AddTokenValidityKeyAsync(TUser user, string tokenValidityKey, DateTime expireDate, CancellationToken cancellationToken = default(CancellationToken));
    void AddTokenValidityKey(TUser user, string tokenValidityKey, DateTime expireDate, CancellationToken cancellationToken = default(CancellationToken));
    Task AddTokenValidityKeyAsync(UserIdentifier user, string tokenValidityKey, DateTime expireDate, CancellationToken cancellationToken = default(CancellationToken));
    void AddTokenValidityKey(UserIdentifier user, string tokenValidityKey, DateTime expireDate, CancellationToken cancellationToken = default(CancellationToken));
    Task<bool> IsTokenValidityKeyValidAsync(TUser user, string tokenValidityKey, CancellationToken cancellationToken = default(CancellationToken));
    bool IsTokenValidityKeyValid(TUser user, string tokenValidityKey, CancellationToken cancellationToken = default(CancellationToken));
    Task RemoveTokenValidityKeyAsync(TUser user, string tokenValidityKey, CancellationToken cancellationToken = default(CancellationToken));
    void RemoveTokenValidityKey(TUser user, string tokenValidityKey, CancellationToken cancellationToken = default(CancellationToken));
    bool IsLockedOut(string userId);
    bool IsLockedOut(TUser user);
    void ResetAccessFailedCount(TUser user);
}
