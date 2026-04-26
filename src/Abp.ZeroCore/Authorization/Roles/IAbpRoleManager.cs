using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Authorization.Users;
using Abp.Organizations;
using Microsoft.AspNetCore.Identity;

namespace Abp.Authorization.Roles;

public interface IAbpRoleManager<TRole, TUser>
    where TRole : AbpRole<TUser>, new()
    where TUser : AbpUser<TUser>
{
    Task<IQueryable<TRole>> GetRolesAsync();
    Task<bool> IsGrantedAsync(string roleName, string permissionName);
    Task<bool> IsGrantedAsync(string roleId, string permissionName, int? fsTagNone=null);
    Task<bool> IsGrantedAsync(TRole role, Permission permission);
    Task<bool> IsGrantedAsync(string roleId, Permission permission);
    bool IsGranted(string roleId, Permission permission);
    Task<IReadOnlyList<Permission>> GetGrantedPermissionsAsync(string roleId, int? fsTagNone=null);
    Task<IReadOnlyList<Permission>> GetGrantedPermissionsAsync(string roleName);
    Task<IReadOnlyList<Permission>> GetGrantedPermissionsAsync(TRole role);
    Task SetGrantedPermissionsAsync(string roleId, IEnumerable<Permission> permissions);
    Task SetGrantedPermissionsAsync(TRole role, IEnumerable<Permission> permissions);
    Task GrantPermissionAsync(TRole role, Permission permission);
    Task ProhibitPermissionAsync(TRole role, Permission permission);
    Task ProhibitAllPermissionsAsync(TRole role);
    Task ResetAllPermissionsAsync(TRole role);
    Task<TRole> GetRoleByIdAsync(string roleId);
    Task<TRole> GetRoleByNameAsync(string roleName);
    TRole GetRoleByName(string roleName);
    Task GrantAllPermissionsAsync(TRole role);
    Task<IdentityResult> CreateStaticRoles(string tenantId);
    Task<IdentityResult> CheckDuplicateRoleNameAsync(string expectedRoleId, string name, string displayName);
    Task<List<TRole>> GetRolesInOrganizationUnitAsync(OrganizationUnit organizationUnit, bool includeChildren = false);
    Task SetOrganizationUnitsAsync(string roleId, params string[] organizationUnitIds);
    Task SetOrganizationUnitsAsync(TRole role, params string[] organizationUnitIds);
    Task<bool> IsInOrganizationUnitAsync(string roleId, string ouId);
    Task<bool> IsInOrganizationUnitAsync(TRole role, OrganizationUnit ou);
    Task AddToOrganizationUnitAsync(string roleId, string ouId, string tenantId);
    Task AddToOrganizationUnitAsync(TRole role, OrganizationUnit ou);
    Task RemoveFromOrganizationUnitAsync(string roleId, string organizationUnitId);
    Task RemoveFromOrganizationUnitAsync(TRole role, OrganizationUnit ou);
    Task<List<OrganizationUnit>> GetOrganizationUnitsAsync(TRole role);
}
