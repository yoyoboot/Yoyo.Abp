using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Abp.Application.Editions;
using Abp.Application.Features;
using Abp.Authorization;
using Abp.Authorization.Roles;
using Abp.Authorization.Users;
using Abp.Configuration;
using Abp.Configuration.Startup;
using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.Domain.Uow;
using Abp.Linq;
using Abp.MultiTenancy;
using Abp.Organizations;
using Abp.Runtime.Caching;
using Abp.Zero.Configuration;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Abp.ZeroCore.SampleApp.Core
{
    public class UserManager : AbpUserManager<Role, User>
    {
        public UserManager(
            RoleManager roleManager,
            UserStore userStore,
            IOptions<IdentityOptions> optionsAccessor,
            IPasswordHasher<User> passwordHasher,
            IEnumerable<IUserValidator<User>> userValidators,
            IEnumerable<IPasswordValidator<User>> passwordValidators,
            ILookupNormalizer keyNormalizer,
            IdentityErrorDescriber errors,
            IServiceProvider services,
            ILogger<UserManager> logger,
            IPermissionManager permissionManager,
            IUnitOfWorkManager unitOfWorkManager,
            ICacheManager cacheManager,
            IRepository<OrganizationUnit, string> organizationUnitRepository,
            IRepository<UserOrganizationUnit, string> userOrganizationUnitRepository,
            IOrganizationUnitSettings organizationUnitSettings,
            ISettingManager settingManager,
            IRepository<UserLogin, string> userLoginRepository) : base(
            roleManager,
            userStore,
            optionsAccessor,
            passwordHasher,
            userValidators,
            passwordValidators,
            keyNormalizer,
            errors,
            services,
            logger,
            permissionManager,
            unitOfWorkManager,
            cacheManager,
            organizationUnitRepository,
            userOrganizationUnitRepository,
            organizationUnitSettings,
            settingManager,
            userLoginRepository
            )
        {
        }
    }

    public class TenantManager : AbpTenantManager<Tenant, User>
    {
        public TenantManager(
            IRepository<Tenant> tenantRepository,
            IRepository<TenantFeatureSetting, string> tenantFeatureRepository,
            EditionManager editionManager,
            IAbpZeroFeatureValueStore featureValueStore) :
            base(
                tenantRepository,
                tenantFeatureRepository,
                editionManager,
                featureValueStore)
        {
        }
    }

    public class EditionManager : AbpEditionManager
    {
        public const string DefaultEditionName = "Standard";

        public EditionManager(
            IRepository<Edition> editionRepository,
            IAbpZeroFeatureValueStore featureValueStore,
            IUnitOfWorkManager unitOfWorkManager)
            : base(
               editionRepository,
               featureValueStore,
               unitOfWorkManager)
        {
        }
    }

    public class RoleManager : AbpRoleManager<Role, User>
    {
        public RoleManager(
            RoleStore store,
            IEnumerable<IRoleValidator<Role>> roleValidators,
            ILookupNormalizer keyNormalizer,
            IdentityErrorDescriber errors,
            ILogger<RoleManager> logger,
            IPermissionManager permissionManager,
            ICacheManager cacheManager,
            IUnitOfWorkManager unitOfWorkManager,
            IRoleManagementConfig roleManagementConfig,
            IRepository<OrganizationUnit, string> organizationUnitRepository,
            IRepository<OrganizationUnitRole, string> organizationUnitRoleRepository
        ) : base(
            store,
            roleValidators,
            keyNormalizer,
            errors,
            logger,
            permissionManager,
            cacheManager,
            unitOfWorkManager,
            roleManagementConfig,
            organizationUnitRepository,
            organizationUnitRoleRepository)
        {
        }
    }

    public class LogInManager : AbpLogInManager<Tenant, Role, User>
    {
        public LogInManager(
            AbpUserManager<Role, User> userManager,
            IMultiTenancyConfig multiTenancyConfig,
            IRepository<Tenant> tenantRepository,
            IUnitOfWorkManager unitOfWorkManager,
            ISettingManager settingManager,
            IRepository<UserLoginAttempt, string> userLoginAttemptRepository,
            IUserManagementConfig userManagementConfig,
            IIocResolver iocResolver,
            IPasswordHasher<User> passwordHasher,
            AbpRoleManager<Role, User> roleManager,
            UserClaimsPrincipalFactory claimsPrincipalFactory
        ) : base(
            userManager,
            multiTenancyConfig,
            tenantRepository,
            unitOfWorkManager,
            settingManager,
            userLoginAttemptRepository,
            userManagementConfig,
            iocResolver,
            passwordHasher,
            roleManager,
            claimsPrincipalFactory)
        {
        }
    }

    public class PermissionChecker : PermissionChecker<Role, User>
    {
        public PermissionChecker(UserManager userManager)
            : base(userManager)
        {
        }
    }

    public class FeatureValueStore : AbpFeatureValueStore<Tenant, User>
    {
        public FeatureValueStore(ICacheManager cacheManager,
            IRepository<TenantFeatureSetting, string> tenantFeatureRepository,
            IRepository<Tenant> tenantRepository,
            IRepository<EditionFeatureSetting, string> editionFeatureRepository,
            IFeatureManager featureManager,
            IUnitOfWorkManager unitOfWorkManager)
            : base(
                cacheManager,
                tenantFeatureRepository,
                tenantRepository,
                editionFeatureRepository,
                featureManager,
                unitOfWorkManager)
        {

        }
    }

    public class RoleStore : AbpRoleStore<Role, User>
    {
        public RoleStore(
            IUnitOfWorkManager unitOfWorkManager,
            IRepository<Role> roleRepository,
            IRepository<RolePermissionSetting, string> rolePermissionSettingRepository
        ) : base(
            unitOfWorkManager,
            roleRepository,
            rolePermissionSettingRepository)
        {
        }
    }

    public class SecurityStampValidator : AbpSecurityStampValidator<Tenant, Role, User>
    {
        public SecurityStampValidator(
            IOptions<SecurityStampValidatorOptions> options,
            SignInManager signInManager,
            ILoggerFactory loggerFactory,
            IUnitOfWorkManager unitOfWorkManager)
            : base(options, signInManager, loggerFactory, unitOfWorkManager)
        {
        }
    }

    public class SignInManager : AbpSignInManager<Tenant, Role, User>
    {
        public SignInManager(
            UserManager userManager,
            IHttpContextAccessor contextAccessor,
            UserClaimsPrincipalFactory claimsFactory,
            IOptions<IdentityOptions> optionsAccessor,
            ILogger<SignInManager<User>> logger,
            IUnitOfWorkManager unitOfWorkManager,
            ISettingManager settingManager,
            IAuthenticationSchemeProvider schemes,
            IUserConfirmation<User> userConfirmation
        ) : base(
            userManager,
            contextAccessor,
            claimsFactory,
            optionsAccessor,
            logger,
            unitOfWorkManager,
            settingManager,
            schemes,
            userConfirmation)
        {
        }
    }

    public class UserStore : AbpUserStore<Role, User>
    {
        public UserStore(
            IUnitOfWorkManager unitOfWorkManager,
            IRepository<User, string> userRepository,
            IRepository<Role> roleRepository,
            IRepository<UserRole, string> userRoleRepository,
            IRepository<UserLogin, string> userLoginRepository,
            IRepository<UserClaim, string> userClaimRepository,
            IRepository<UserPermissionSetting, string> userPermissionSettingRepository,
            IRepository<UserOrganizationUnit, string> userOrganizationUnitRepository,
            IRepository<OrganizationUnitRole, string> organizationUnitRoleRepository,
            IRepository<UserToken, string> userTokenRepository
            ) : base(
            unitOfWorkManager,
            userRepository,
            roleRepository,
            userRoleRepository,
            userLoginRepository,
            userClaimRepository,
            userPermissionSettingRepository,
            userOrganizationUnitRepository,
            organizationUnitRoleRepository,
            userTokenRepository)
        {
        }
    }

    public class UserClaimsPrincipalFactory : AbpUserClaimsPrincipalFactory<User, Role>
    {
        public UserClaimsPrincipalFactory(
            UserManager userManager,
            RoleManager roleManager,
            IOptions<IdentityOptions> optionsAccessor, 
            IUnitOfWorkManager unitOfWorkManager)
            : base(
                userManager,
                roleManager,
                optionsAccessor,
                unitOfWorkManager)
        {
            
        }

        [UnitOfWork]
        public override async Task<ClaimsPrincipal> CreateAsync(User user)
        {
            return await base.CreateAsync(user);
        }
    }
}
