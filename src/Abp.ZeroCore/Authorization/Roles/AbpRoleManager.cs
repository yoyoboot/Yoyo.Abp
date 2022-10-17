using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Abp.Application.Features;
using Abp.Authorization.Users;
using Abp.Collections.Extensions;
using Abp.Domain.Repositories;
using Abp.Domain.Services;
using Abp.Domain.Uow;
using Abp.Localization;
using Abp.MultiTenancy;
using Abp.Organizations;
using Abp.Runtime.Caching;
using Abp.Runtime.Session;
using Abp.UI;
using Abp.Zero;
using Abp.Zero.Configuration;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;

namespace Abp.Authorization.Roles
{
    public class AbpRoleManager<TRole, TUser> : RoleManager<TRole>, IDomainService
        where TRole : AbpRole<TUser>, new()
        where TUser : AbpUser<TUser>
    {
        public ILocalizationManager LocalizationManager { get; set; }

        protected string LocalizationSourceName { get; set; }

        public IAbpSession AbpSession { get; set; }

        public IRoleManagementConfig RoleManagementConfig { get; }

        public FeatureDependencyContext FeatureDependencyContext { get; set; }

        private IRolePermissionStore<TRole> RolePermissionStore
        {
            get
            {
                if (!(Store is IRolePermissionStore<TRole>))
                {
                    throw new AbpException("Store is not IRolePermissionStore");
                }

                return Store as IRolePermissionStore<TRole>;
            }
        }

        protected AbpRoleStore<TRole, TUser> AbpStore { get; }

        private readonly IPermissionManager _permissionManager;
        private readonly ICacheManager _cacheManager;
        private readonly IUnitOfWorkManager _unitOfWorkManager;
        private readonly IRepository<OrganizationUnit, string> _organizationUnitRepository;
        private readonly IRepository<OrganizationUnitRole, string> _organizationUnitRoleRepository;

        public AbpRoleManager(
            AbpRoleStore<TRole, TUser> store,
            IEnumerable<IRoleValidator<TRole>> roleValidators,
            ILookupNormalizer keyNormalizer,
            IdentityErrorDescriber errors,
            ILogger<AbpRoleManager<TRole, TUser>> logger,
            IPermissionManager permissionManager,
            ICacheManager cacheManager,
            IUnitOfWorkManager unitOfWorkManager,
            IRoleManagementConfig roleManagementConfig,
            IRepository<OrganizationUnit, string> organizationUnitRepository,
            IRepository<OrganizationUnitRole, string> organizationUnitRoleRepository)
            : base(
                store,
                roleValidators,
                keyNormalizer,
                errors,
                logger)
        {
            _permissionManager = permissionManager;
            _cacheManager = cacheManager;
            _unitOfWorkManager = unitOfWorkManager;

            RoleManagementConfig = roleManagementConfig;
            _organizationUnitRepository = organizationUnitRepository;
            _organizationUnitRoleRepository = organizationUnitRoleRepository;
            AbpStore = store;
            AbpSession = NullAbpSession.Instance;
            LocalizationManager = NullLocalizationManager.Instance;
            LocalizationSourceName = AbpZeroConsts.LocalizationSourceName;
        }

        /// <summary>
        /// Checks if a role is granted for a permission.
        /// </summary>
        /// <param name="roleName">The role's name to check it's permission</param>
        /// <param name="permissionName">Name of the permission</param>
        /// <returns>True, if the role has the permission</returns>
        public virtual async Task<bool> IsGrantedAsync(string roleName, string permissionName)
        {
            return await IsGrantedAsync((await GetRoleByNameAsync(roleName)).Id,
                _permissionManager.GetPermission(permissionName));
        }

        /// <summary>
        /// Checks if a role has a permission.
        /// </summary>
        /// <param name="roleId">The role's id to check it's permission</param>
        /// <param name="permissionName">Name of the permission</param>
        /// <returns>True, if the role has the permission</returns>
        public virtual async Task<bool> IsGrantedAsync(string roleId, string permissionName, int? fsTagNone=null)
        {
            return await IsGrantedAsync(roleId, _permissionManager.GetPermission(permissionName));
        }

        /// <summary>
        /// Checks if a role is granted for a permission.
        /// </summary>
        /// <param name="role">The role</param>
        /// <param name="permission">The permission</param>
        /// <returns>True, if the role has the permission</returns>
        public Task<bool> IsGrantedAsync(TRole role, Permission permission)
        {
            return IsGrantedAsync(role.Id, permission);
        }

        /// <summary>
        /// Checks if a role is granted for a permission.
        /// </summary>
        /// <param name="roleId">role id</param>
        /// <param name="permission">The permission</param>
        /// <returns>True, if the role has the permission</returns>
        public virtual async Task<bool> IsGrantedAsync(string roleId, Permission permission)
        {
            //Get cached role permissions
            var cacheItem = await GetRolePermissionCacheItemAsync(roleId);

            //Check the permission
            return cacheItem.GrantedPermissions.Contains(permission.Name);
        }

        /// <summary>
        /// Checks if a role is granted for a permission.
        /// </summary>
        /// <param name="roleId">role id</param>
        /// <param name="permission">The permission</param>
        /// <returns>True, if the role has the permission</returns>
        public virtual bool IsGranted(string roleId, Permission permission)
        {
            //Get cached role permissions
            var cacheItem = GetRolePermissionCacheItem(roleId);

            //Check the permission
            return cacheItem.GrantedPermissions.Contains(permission.Name);
        }

        /// <summary>
        /// Gets granted permission names for a role.
        /// </summary>
        /// <param name="roleId">Role id</param>
        /// <returns>List of granted permissions</returns>
        public virtual async Task<IReadOnlyList<Permission>> GetGrantedPermissionsAsync(string roleId, int? fsTagNone=null)
        {
            return await GetGrantedPermissionsAsync(await GetRoleByIdAsync(roleId));
        }

        /// <summary>
        /// Gets granted permission names for a role.
        /// </summary>
        /// <param name="roleName">Role name</param>
        /// <returns>List of granted permissions</returns>
        public virtual async Task<IReadOnlyList<Permission>> GetGrantedPermissionsAsync(string roleName)
        {
            return await GetGrantedPermissionsAsync(await GetRoleByNameAsync(roleName));
        }

        /// <summary>
        /// Gets granted permissions for a role.
        /// </summary>
        /// <param name="role">Role</param>
        /// <returns>List of granted permissions</returns>
        public virtual async Task<IReadOnlyList<Permission>> GetGrantedPermissionsAsync(TRole role)
        {
            var cacheItem = await GetRolePermissionCacheItemAsync(role.Id);
            var allPermissions = _permissionManager.GetAllPermissions();
            return allPermissions.Where(x => cacheItem.GrantedPermissions.Contains(x.Name)).ToList();
        }

        /// <summary>
        /// Sets all granted permissions of a role at once.
        /// Prohibits all other permissions.
        /// </summary>
        /// <param name="roleId">Role id</param>
        /// <param name="permissions">Permissions</param>
        public virtual async Task SetGrantedPermissionsAsync(string roleId, IEnumerable<Permission> permissions)
        {
            await SetGrantedPermissionsAsync(await GetRoleByIdAsync(roleId), permissions);
        }

        /// <summary>
        /// Sets all granted permissions of a role at once.
        /// Prohibits all other permissions.
        /// </summary>
        /// <param name="role">The role</param>
        /// <param name="permissions">Permissions</param>
        public virtual async Task SetGrantedPermissionsAsync(TRole role, IEnumerable<Permission> permissions)
        {
            var oldPermissions = await GetGrantedPermissionsAsync(role);
            var newPermissions = permissions.ToArray();

            foreach (var permission in oldPermissions.Where(p =>
                !newPermissions.Contains(p, PermissionEqualityComparer.Instance)))
            {
                await ProhibitPermissionAsync(role, permission);
            }

            foreach (var permission in newPermissions.Where(p =>
                !oldPermissions.Contains(p, PermissionEqualityComparer.Instance)))
            {
                await GrantPermissionAsync(role, permission);
            }
        }

        /// <summary>
        /// Grants a permission for a role.
        /// </summary>
        /// <param name="role">Role</param>
        /// <param name="permission">Permission</param>
        public async Task GrantPermissionAsync(TRole role, Permission permission)
        {
            if (await IsGrantedAsync(role.Id, permission))
            {
                return;
            }

            await RolePermissionStore.RemovePermissionAsync(role, new PermissionGrantInfo(permission.Name, false));
            await RolePermissionStore.AddPermissionAsync(role, new PermissionGrantInfo(permission.Name, true));
        }

        /// <summary>
        /// Prohibits a permission for a role.
        /// </summary>
        /// <param name="role">Role</param>
        /// <param name="permission">Permission</param>
        public async Task ProhibitPermissionAsync(TRole role, Permission permission)
        {
            if (!await IsGrantedAsync(role.Id, permission))
            {
                return;
            }

            await RolePermissionStore.RemovePermissionAsync(role, new PermissionGrantInfo(permission.Name, true));
            await RolePermissionStore.AddPermissionAsync(role, new PermissionGrantInfo(permission.Name, false));
        }

        /// <summary>
        /// Prohibits all permissions for a role.
        /// </summary>
        /// <param name="role">Role</param>
        public async Task ProhibitAllPermissionsAsync(TRole role)
        {
            foreach (var permission in _permissionManager.GetAllPermissions())
            {
                await ProhibitPermissionAsync(role, permission);
            }
        }

        /// <summary>
        /// Resets all permission settings for a role.
        /// It removes all permission settings for the role.
        /// Role will have permissions for which <see cref="StaticRoleDefinition.IsGrantedByDefault"/> returns true.
        /// </summary>
        /// <param name="role">Role</param>
        public async Task ResetAllPermissionsAsync(TRole role)
        {
            await RolePermissionStore.RemoveAllPermissionSettingsAsync(role);
        }

        /// <summary>
        /// Creates a role.
        /// </summary>
        /// <param name="role">Role</param>
        public override async Task<IdentityResult> CreateAsync(TRole role)
        {
            var result = await CheckDuplicateRoleNameAsync(role.Id, role.Name, role.DisplayName);
            if (!result.Succeeded)
            {
                return result;
            }

            var tenantId = GetCurrentTenantId();
            if (tenantId.HasValue() && !role.TenantId.HasValue())
            {
                role.TenantId = tenantId;
            }

            return await base.CreateAsync(role);
        }

        public override async Task<IdentityResult> UpdateAsync(TRole role)
        {
            var result = await CheckDuplicateRoleNameAsync(role.Id, role.Name, role.DisplayName);
            if (!result.Succeeded)
            {
                return result;
            }

            return await base.UpdateAsync(role);
        }

        /// <summary>
        /// Deletes a role.
        /// </summary>
        /// <param name="role">Role</param>
        public override async Task<IdentityResult> DeleteAsync(TRole role)
        {
            if (role.IsStatic)
            {
                throw new UserFriendlyException(string.Format(L("CanNotDeleteStaticRole"), role.Name));
            }

            return await base.DeleteAsync(role);
        }

        /// <summary>
        /// Gets a role by given id.
        /// Throws exception if no role with given id.
        /// </summary>
        /// <param name="roleId">Role id</param>
        /// <returns>Role</returns>
        /// <exception cref="AbpException">Throws exception if no role with given id</exception>
        public virtual async Task<TRole> GetRoleByIdAsync(string roleId)
        {
            var role = await FindByIdAsync(roleId.ToString());
            if (role == null)
            {
                throw new AbpException("There is no role with id: " + roleId);
            }

            return role;
        }

        /// <summary>
        /// Gets a role by given name.
        /// Throws exception if no role with given roleName.
        /// </summary>
        /// <param name="roleName">Role name</param>
        /// <returns>Role</returns>
        /// <exception cref="AbpException">Throws exception if no role with given roleName</exception>
        public virtual async Task<TRole> GetRoleByNameAsync(string roleName)
        {
            var role = await FindByNameAsync(roleName);
            if (role == null)
            {
                throw new AbpException("There is no role with name: " + roleName);
            }

            return role;
        }

        /// <summary>
        /// Gets a role by given name.
        /// Throws exception if no role with given roleName.
        /// </summary>
        /// <param name="roleName">Role name</param>
        /// <returns>Role</returns>
        /// <exception cref="AbpException">Throws exception if no role with given roleName</exception>
        public virtual TRole GetRoleByName(string roleName)
        {
            var normalizedRoleName = roleName.ToUpperInvariant();

            var role = AbpStore.FindByName(normalizedRoleName);
            if (role == null)
            {
                throw new AbpException("There is no role with name: " + roleName);
            }

            return role;
        }

        public async Task GrantAllPermissionsAsync(TRole role)
        {
            FeatureDependencyContext.TenantId = role.TenantId;

            var permissions = _permissionManager.GetAllPermissions(role.GetMultiTenancySide())
                .Where(permission =>
                    permission.FeatureDependency == null ||
                    permission.FeatureDependency.IsSatisfied(FeatureDependencyContext)
                );

            await SetGrantedPermissionsAsync(role, permissions);
        }

        public virtual async Task<IdentityResult> CreateStaticRoles(string tenantId)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                var staticRoleDefinitions = RoleManagementConfig.StaticRoles.Where(
                    sr => sr.Side == MultiTenancySides.Tenant
                );

                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    foreach (var staticRoleDefinition in staticRoleDefinitions)
                    {
                        var role = MapStaticRoleDefinitionToRole(tenantId, staticRoleDefinition);

                        var identityResult = await CreateAsync(role);
                        if (!identityResult.Succeeded)
                        {
                            return identityResult;
                        }
                    }
                }

                return IdentityResult.Success;
            });
        }

        public virtual async Task<IdentityResult> CheckDuplicateRoleNameAsync(
            string expectedRoleId,
            string name,
            string displayName)
        {
            var role = await FindByNameAsync(name);
            if (role != null && role.Id != expectedRoleId)
            {
                throw new UserFriendlyException(string.Format(L("RoleNameIsAlreadyTaken"), name));
            }

            role = await FindByDisplayNameAsync(displayName);
            if (role != null && role.Id != expectedRoleId)
            {
                throw new UserFriendlyException(string.Format(L("RoleDisplayNameIsAlreadyTaken"), displayName));
            }

            return IdentityResult.Success;
        }

        /// <summary>
        /// Gets roles of a given organizationUnit
        /// </summary>
        /// <param name="organizationUnit">OrganizationUnit to get belonging roles </param>
        /// <param name="includeChildren">Includes roles for children organization units to result when true. Default is false</param>
        /// <returns></returns>
        public virtual async Task<List<TRole>> GetRolesInOrganizationUnit(
            OrganizationUnit organizationUnit,
            bool includeChildren = false)
        {
            var result = _unitOfWorkManager.WithUnitOfWork(() =>
            {
                if (!includeChildren)
                {
                    var query = from organizationUnitRole in _organizationUnitRoleRepository.GetAll()
                        join role in Roles on organizationUnitRole.RoleId equals role.Id
                        where organizationUnitRole.OrganizationUnitId == organizationUnit.Id
                        select role;

                    return query.ToList();
                }
                else
                {
                    var query = from organizationUnitRole in _organizationUnitRoleRepository.GetAll()
                        join role in Roles on organizationUnitRole.RoleId equals role.Id
                        join ou in _organizationUnitRepository.GetAll() on organizationUnitRole.OrganizationUnitId
                            equals
                            ou.Id
                        where ou.Code.StartsWith(organizationUnit.Code)
                        select role;

                    return query.ToList();
                }
            });

            return await Task.FromResult(result);
        }

        public virtual async Task SetOrganizationUnitsAsync(string roleId, params string[] organizationUnitIds)
        {
            await SetOrganizationUnitsAsync(
                await GetRoleByIdAsync(roleId),
                organizationUnitIds
            );
        }

        public virtual async Task SetOrganizationUnitsAsync(TRole role, params string[] organizationUnitIds)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                if (organizationUnitIds == null)
                {
                    organizationUnitIds = new string[0];
                }

                var currentOus = await GetOrganizationUnitsAsync(role);

                //Remove from removed OUs
                foreach (var currentOu in currentOus)
                {
                    if (!organizationUnitIds.Contains(currentOu.Id))
                    {
                        await RemoveFromOrganizationUnitAsync(role, currentOu);
                    }
                }

                //Add to added OUs
                foreach (var organizationUnitId in organizationUnitIds)
                {
                    if (currentOus.All(ou => ou.Id != organizationUnitId))
                    {
                        await AddToOrganizationUnitAsync(
                            role,
                            await _organizationUnitRepository.GetAsync(organizationUnitId)
                        );
                    }
                }
            });
        }

        public virtual async Task<bool> IsInOrganizationUnitAsync(string roleId, string ouId)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
                await IsInOrganizationUnitAsync(
                    await GetRoleByIdAsync(roleId),
                    await _organizationUnitRepository.GetAsync(ouId)
                )
            );
        }

        public virtual async Task<bool> IsInOrganizationUnitAsync(TRole role, OrganizationUnit ou)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                return await _organizationUnitRoleRepository.CountAsync(uou =>
                    uou.RoleId == role.Id && uou.OrganizationUnitId == ou.Id
                ) > 0;
            });
        }

        public virtual async Task AddToOrganizationUnitAsync(string roleId, string ouId, string tenantId)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await AddToOrganizationUnitAsync(
                    await GetRoleByIdAsync(roleId),
                    await _organizationUnitRepository.GetAsync(ouId)
                );
            });
        }

        public virtual async Task AddToOrganizationUnitAsync(TRole role, OrganizationUnit ou)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                if (await IsInOrganizationUnitAsync(role, ou))
                {
                    return;
                }

                await _organizationUnitRoleRepository.InsertAsync(new OrganizationUnitRole(role.TenantId, role.Id, ou.Id));
            });
        }

        public async Task RemoveFromOrganizationUnitAsync(string roleId, string organizationUnitId)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await RemoveFromOrganizationUnitAsync(
                    await GetRoleByIdAsync(roleId),
                    await _organizationUnitRepository.GetAsync(organizationUnitId)
                );
            });
        }

        public virtual async Task RemoveFromOrganizationUnitAsync(TRole role, OrganizationUnit ou)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await _organizationUnitRoleRepository.DeleteAsync(uor =>
                    uor.RoleId == role.Id && uor.OrganizationUnitId == ou.Id
                );
            });
        }

        public virtual async Task<List<OrganizationUnit>> GetOrganizationUnitsAsync(TRole role)
        {
            var result = _unitOfWorkManager.WithUnitOfWork(() =>
            {
                var query = from uor in _organizationUnitRoleRepository.GetAll()
                    join ou in _organizationUnitRepository.GetAll() on uor.OrganizationUnitId equals ou.Id
                    where uor.RoleId == role.Id
                    select ou;

                return query.ToList();
            });

            return await Task.FromResult(result);
        }

        private Task<TRole> FindByDisplayNameAsync(string displayName)
        {
            return AbpStore.FindByDisplayNameAsync(displayName);
        }

        private async Task<RolePermissionCacheItem> GetRolePermissionCacheItemAsync(string roleId)
        {
            var cacheKey = roleId + "@" + (GetCurrentTenantId() ?? "0");
            return await _cacheManager.GetRolePermissionCache().GetAsync(cacheKey, async () =>
            {
                var newCacheItem = new RolePermissionCacheItem(roleId);

                var role = await Store.FindByIdAsync(roleId.ToString(), CancellationToken);
                if (role == null)
                {
                    throw new AbpException("There is no role with given id: " + roleId);
                }

                var staticRoleDefinition = RoleManagementConfig.StaticRoles.FirstOrDefault(r =>
                    r.RoleName == role.Name && r.Side == role.GetMultiTenancySide()
                );

                if (staticRoleDefinition != null)
                {
                    foreach (var permission in _permissionManager.GetAllPermissions())
                    {
                        if (staticRoleDefinition.IsGrantedByDefault(permission))
                        {
                            newCacheItem.GrantedPermissions.Add(permission.Name);
                        }
                    }
                }

                foreach (var permissionInfo in await RolePermissionStore.GetPermissionsAsync(roleId))
                {
                    if (permissionInfo.IsGranted)
                    {
                        newCacheItem.GrantedPermissions.AddIfNotContains(permissionInfo.Name);
                    }
                    else
                    {
                        newCacheItem.GrantedPermissions.Remove(permissionInfo.Name);
                    }
                }

                return newCacheItem;
            });
        }

        private RolePermissionCacheItem GetRolePermissionCacheItem(string roleId)
        {
            var cacheKey = roleId + "@" + (GetCurrentTenantId() ?? "0");
            return _cacheManager.GetRolePermissionCache().Get(cacheKey, () =>
            {
                var newCacheItem = new RolePermissionCacheItem(roleId);

                var role = AbpStore.FindById(roleId.ToString(), CancellationToken);
                if (role == null)
                {
                    throw new AbpException("There is no role with given id: " + roleId);
                }

                var staticRoleDefinition = RoleManagementConfig.StaticRoles.FirstOrDefault(r =>
                    r.RoleName == role.Name && r.Side == role.GetMultiTenancySide()
                );

                if (staticRoleDefinition != null)
                {
                    foreach (var permission in _permissionManager.GetAllPermissions())
                    {
                        if (staticRoleDefinition.IsGrantedByDefault(permission))
                        {
                            newCacheItem.GrantedPermissions.Add(permission.Name);
                        }
                    }
                }

                foreach (var permissionInfo in RolePermissionStore.GetPermissions(roleId))
                {
                    if (permissionInfo.IsGranted)
                    {
                        newCacheItem.GrantedPermissions.AddIfNotContains(permissionInfo.Name);
                    }
                    else
                    {
                        newCacheItem.GrantedPermissions.Remove(permissionInfo.Name);
                    }
                }

                return newCacheItem;
            });
        }

        protected virtual string L(string name)
        {
            return LocalizationManager.GetString(LocalizationSourceName, name);
        }

        protected virtual string L(string name, CultureInfo cultureInfo)
        {
            return LocalizationManager.GetString(LocalizationSourceName, name, cultureInfo);
        }

        protected virtual TRole MapStaticRoleDefinitionToRole(string tenantId, StaticRoleDefinition staticRoleDefinition)
        {
            return new TRole
            {
                TenantId = tenantId,
                Name = staticRoleDefinition.RoleName,
                DisplayName = staticRoleDefinition.RoleDisplayName,
                IsStatic = true
            };
        }

        private string GetCurrentTenantId()
        {
            if (_unitOfWorkManager.Current != null)
            {
                return _unitOfWorkManager.Current.GetTenantId();
            }

            return AbpSession.TenantId;
        }
    }
}
