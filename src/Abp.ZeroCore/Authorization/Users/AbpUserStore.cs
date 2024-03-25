using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using System.Transactions;
using Abp.Authorization.Roles;
using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.Domain.Uow;
using Abp.Extensions;
using Abp.Linq;
using Abp.Organizations;
using Abp.Runtime.Session;
using Abp.Zero;
using Castle.Core.Logging;
using JetBrains.Annotations;
using Microsoft.AspNetCore.Identity;

namespace Abp.Authorization.Users
{
    /// <summary>
    /// Represents a new instance of a persistence store for the specified user and role types.
    /// </summary>
    public class AbpUserStore<TRole, TUser> :
        IUserLoginStore<TUser>,
        IUserRoleStore<TUser>,
        IUserClaimStore<TUser>,
        IUserPasswordStore<TUser>,
        IUserSecurityStampStore<TUser>,
        IUserEmailStore<TUser>,
        IUserLockoutStore<TUser>,
        IUserPhoneNumberStore<TUser>,
        IUserTwoFactorStore<TUser>,
        IUserAuthenticationTokenStore<TUser>,
        IUserPermissionStore<TUser>,
        IQueryableUserStore<TUser>,
        IUserAuthenticatorKeyStore<TUser>,
        ITransientDependency
        where TRole : AbpRole<TUser>
        where TUser : AbpUser<TUser>
    {
        public ILogger Logger { get; set; }

        /// <summary>
        /// Gets or sets the <see cref="IdentityErrorDescriber"/> for any error that occurred with the current operation.
        /// </summary>
        public IdentityErrorDescriber ErrorDescriber { get; set; }

        /// <summary>
        /// Gets or sets a flag indicating if changes should be persisted after CreateAsync, UpdateAsync and DeleteAsync are called.
        /// </summary>
        /// <value>
        /// True if changes should be automatically persisted, otherwise false.
        /// </value>
        public bool AutoSaveChanges { get; set; } = true;

        public IAbpSession AbpSession { get; set; }

        public IQueryable<TUser> Users => UserRepository.GetAll();

        public IRepository<TUser, string> UserRepository { get; }

        public IAsyncQueryableExecuter AsyncQueryableExecuter { get; set; }

        private readonly IRepository<TRole> _roleRepository;
        private readonly IRepository<UserRole, string> _userRoleRepository;
        private readonly IRepository<UserLogin, string> _userLoginRepository;
        private readonly IRepository<UserClaim, string> _userClaimRepository;
        private readonly IRepository<UserPermissionSetting, string> _userPermissionSettingRepository;
        private readonly IRepository<UserOrganizationUnit, string> _userOrganizationUnitRepository;
        private readonly IRepository<OrganizationUnitRole, string> _organizationUnitRoleRepository;
        private readonly IRepository<UserToken, string> _userTokenRepository;

        private readonly IUnitOfWorkManager _unitOfWorkManager;

        public AbpUserStore(
            IUnitOfWorkManager unitOfWorkManager,
            IRepository<TUser, string> userRepository,
            IRepository<TRole> roleRepository,
            IRepository<UserRole, string> userRoleRepository,
            IRepository<UserLogin, string> userLoginRepository,
            IRepository<UserClaim, string> userClaimRepository,
            IRepository<UserPermissionSetting, string> userPermissionSettingRepository,
            IRepository<UserOrganizationUnit, string> userOrganizationUnitRepository,
            IRepository<OrganizationUnitRole, string> organizationUnitRoleRepository,
            IRepository<UserToken, string> userTokenRepository)
        {
            _unitOfWorkManager = unitOfWorkManager;
            UserRepository = userRepository;
            _roleRepository = roleRepository;
            _userRoleRepository = userRoleRepository;
            _userLoginRepository = userLoginRepository;
            _userClaimRepository = userClaimRepository;
            _userPermissionSettingRepository = userPermissionSettingRepository;
            _userOrganizationUnitRepository = userOrganizationUnitRepository;
            _organizationUnitRoleRepository = organizationUnitRoleRepository;
            _userTokenRepository = userTokenRepository;

            AbpSession = NullAbpSession.Instance;
            ErrorDescriber = new IdentityErrorDescriber();
            Logger = NullLogger.Instance;
            AsyncQueryableExecuter = NullAsyncQueryableExecuter.Instance;
        }

        /// <summary>Saves the current store.</summary>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        protected Task SaveChangesAsync(CancellationToken cancellationToken)
        {
            if (!AutoSaveChanges || _unitOfWorkManager.Current == null)
            {
                return Task.CompletedTask;
            }

            return _unitOfWorkManager.Current.SaveChangesAsync();
        }

        /// <summary>Saves the current store.</summary>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        protected void SaveChanges(CancellationToken cancellationToken)
        {
            if (!AutoSaveChanges || _unitOfWorkManager.Current == null)
            {
                return;
            }

            _unitOfWorkManager.Current.SaveChanges();
        }

        /// <summary>
        /// Gets the user identifier for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose identifier should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the identifier for the specified <paramref name="user"/>.</returns>
        public virtual Task<string> GetUserIdAsync([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return Task.FromResult(GetUserId(user, cancellationToken));
        }

        /// <summary>
        /// Gets the user identifier for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose identifier should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the identifier for the specified <paramref name="user"/>.</returns>
        public virtual string GetUserId([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.Id.ToString();
        }

        /// <summary>
        /// Gets the user name for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose name should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the name for the specified <paramref name="user"/>.</returns>
        public virtual Task<string> GetUserNameAsync([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return Task.FromResult(GetUserName(user, cancellationToken));
        }

        /// <summary>
        /// Gets the user name for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose name should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the name for the specified <paramref name="user"/>.</returns>
        public virtual string GetUserName([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.UserName;
        }

        /// <summary>
        /// Sets the given <paramref name="userName" /> for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose name should be set.</param>
        /// <param name="userName">The user name to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetUserNameAsync([NotNull] TUser user, string userName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            SetUserName(user, userName, cancellationToken);
            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the given <paramref name="userName" /> for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose name should be set.</param>
        /// <param name="userName">The user name to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetUserName([NotNull] TUser user, string userName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.UserName = userName;
        }

        /// <summary>
        /// Gets the normalized user name for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose normalized name should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the normalized user name for the specified <paramref name="user"/>.</returns>
        public virtual Task<string> GetNormalizedUserNameAsync([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return Task.FromResult(GetNormalizedUserName(user, cancellationToken));
        }

        /// <summary>
        /// Gets the normalized user name for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose normalized name should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the normalized user name for the specified <paramref name="user"/>.</returns>
        public virtual string GetNormalizedUserName([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.NormalizedUserName;
        }

        /// <summary>
        /// Sets the given normalized name for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose name should be set.</param>
        /// <param name="normalizedName">The normalized name to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetNormalizedUserNameAsync([NotNull] TUser user, string normalizedName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            SetNormalizedUserName(user, normalizedName, cancellationToken);
            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the given normalized name for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose name should be set.</param>
        /// <param name="normalizedName">The normalized name to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetNormalizedUserName([NotNull] TUser user, string normalizedName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.NormalizedUserName = normalizedName;
        }

        /// <summary>
        /// Creates the specified <paramref name="user"/> in the user store.
        /// </summary>
        /// <param name="user">The user to create.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the <see cref="IdentityResult"/> of the creation operation.</returns>
        public virtual async Task<IdentityResult> CreateAsync([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                await UserRepository.InsertAsync(user);
                await SaveChangesAsync(cancellationToken);

                return IdentityResult.Success;
            });
        }

        /// <summary>
        /// Creates the specified <paramref name="user"/> in the user store.
        /// </summary>
        /// <param name="user">The user to create.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the <see cref="IdentityResult"/> of the creation operation.</returns>
        public virtual IdentityResult Create([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                UserRepository.Insert(user);
                SaveChanges(cancellationToken);

                return IdentityResult.Success;
            });
        }

        /// <summary>
        /// Updates the specified <paramref name="user"/> in the user store.
        /// </summary>
        /// <param name="user">The user to update.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the <see cref="IdentityResult"/> of the update operation.</returns>
        public virtual async Task<IdentityResult> UpdateAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                user.ConcurrencyStamp = Guid.NewGuid().ToString();
                await UserRepository.UpdateAsync(user);

                try
                {
                    await SaveChangesAsync(cancellationToken);
                }
                catch (AbpDbConcurrencyException ex)
                {
                    Logger.Warn(ex.ToString(), ex);
                    return IdentityResult.Failed(ErrorDescriber.ConcurrencyFailure());
                }

                await SaveChangesAsync(cancellationToken);

                return IdentityResult.Success;
            });
        }

        /// <summary>
        /// Updates the specified <paramref name="user"/> in the user store.
        /// </summary>
        /// <param name="user">The user to update.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the <see cref="IdentityResult"/> of the update operation.</returns>
        public virtual IdentityResult Update([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                user.ConcurrencyStamp = Guid.NewGuid().ToString();
                UserRepository.Update(user);

                try
                {
                    SaveChanges(cancellationToken);
                }
                catch (AbpDbConcurrencyException ex)
                {
                    Logger.Warn(ex.ToString(), ex);
                    return IdentityResult.Failed(ErrorDescriber.ConcurrencyFailure());
                }

                SaveChanges(cancellationToken);

                return IdentityResult.Success;
            });
        }

        /// <summary>
        /// Deletes the specified <paramref name="user"/> from the user store.
        /// </summary>
        /// <param name="user">The user to delete.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the <see cref="IdentityResult"/> of the update operation.</returns>
        public virtual async Task<IdentityResult> DeleteAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                await UserRepository.DeleteAsync(user);

                try
                {
                    await SaveChangesAsync(cancellationToken);
                }
                catch (AbpDbConcurrencyException ex)
                {
                    Logger.Warn(ex.ToString(), ex);
                    return IdentityResult.Failed(ErrorDescriber.ConcurrencyFailure());
                }

                await SaveChangesAsync(cancellationToken);

                return IdentityResult.Success;
            });
        }

        /// <summary>
        /// Deletes the specified <paramref name="user"/> from the user store.
        /// </summary>
        /// <param name="user">The user to delete.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the <see cref="IdentityResult"/> of the update operation.</returns>
        public virtual IdentityResult Delete(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                UserRepository.Delete(user);

                try
                {
                    SaveChanges(cancellationToken);
                }
                catch (AbpDbConcurrencyException ex)
                {
                    Logger.Warn(ex.ToString(), ex);
                    return IdentityResult.Failed(ErrorDescriber.ConcurrencyFailure());
                }

                SaveChanges(cancellationToken);

                return IdentityResult.Success;
            });
        }

        /// <summary>
        /// Finds and returns a user, if any, who has the specified <paramref name="userId"/>.
        /// </summary>
        /// <param name="userId">The user ID to search for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, containing the user matching the specified <paramref name="userId"/> if it exists.
        /// </returns>
        public virtual async Task<TUser> FindByIdAsync(string userId,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                return await UserRepository.FirstOrDefaultAsync(userId);
            });
        }

        /// <summary>
        /// Finds and returns a user, if any, who has the specified <paramref name="userId"/>.
        /// </summary>
        /// <param name="userId">The user ID to search for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, containing the user matching the specified <paramref name="userId"/> if it exists.
        /// </returns>
        public virtual TUser FindById(string userId, CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                return UserRepository.FirstOrDefault(userId);
            });
        }

        /// <summary>
        /// Finds and returns a user, if any, who has the specified normalized user name.
        /// </summary>
        /// <param name="normalizedUserName">The normalized user name to search for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, containing the user matching the specified <paramref name="normalizedUserName"/> if it exists.
        /// </returns>
        public virtual async Task<TUser> FindByNameAsync([NotNull] string normalizedUserName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(normalizedUserName, nameof(normalizedUserName));
                return await UserRepository.FirstOrDefaultAsync(u => u.NormalizedUserName == normalizedUserName);
            });
        }

        /// <summary>
        /// Finds and returns a user, if any, who has the specified normalized user name.
        /// </summary>
        /// <param name="normalizedUserName">The normalized user name to search for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, containing the user matching the specified <paramref name="normalizedUserName"/> if it exists.
        /// </returns>
        public virtual TUser FindByName(
            [NotNull] string normalizedUserName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(normalizedUserName, nameof(normalizedUserName));
                return UserRepository.FirstOrDefault(u => u.NormalizedUserName == normalizedUserName);
            });
        }

        /// <summary>
        /// Sets the password hash for a user.
        /// </summary>
        /// <param name="user">The user to set the password hash for.</param>
        /// <param name="passwordHash">The password hash to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetPasswordHashAsync([NotNull] TUser user, string passwordHash,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            SetPasswordHash(user, passwordHash, cancellationToken);
            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the password hash for a user.
        /// </summary>
        /// <param name="user">The user to set the password hash for.</param>
        /// <param name="passwordHash">The password hash to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetPasswordHash(
            [NotNull] TUser user, string passwordHash,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();
            Check.NotNull(user, nameof(user));
            user.Password = passwordHash;
        }

        /// <summary>
        /// Gets the password hash for a user.
        /// </summary>
        /// <param name="user">The user to retrieve the password hash for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> that contains the password hash for the user.</returns>
        public virtual Task<string> GetPasswordHashAsync([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();
            Check.NotNull(user, nameof(user));
            return Task.FromResult(user.Password);
        }

        /// <summary>
        /// Gets the password hash for a user.
        /// </summary>
        /// <param name="user">The user to retrieve the password hash for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> that contains the password hash for the user.</returns>
        public virtual string GetPasswordHash([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();
            Check.NotNull(user, nameof(user));
            return user.Password;
        }

        /// <summary>
        /// Returns a flag indicating if the specified user has a password.
        /// </summary>
        /// <param name="user">The user to retrieve the password hash for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> containing a flag indicating if the specified user has a password. If the 
        /// user has a password the returned value with be true, otherwise it will be false.</returns>
        public virtual Task<bool> HasPasswordAsync([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();
            Check.NotNull(user, nameof(user));
            return Task.FromResult(user.Password != null);
        }

        /// <summary>
        /// Returns a flag indicating if the specified user has a password.
        /// </summary>
        /// <param name="user">The user to retrieve the password hash for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> containing a flag indicating if the specified user has a password. If the 
        /// user has a password the returned value with be true, otherwise it will be false.</returns>
        public virtual bool HasPassword([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();
            Check.NotNull(user, nameof(user));
            return user.Password != null;
        }

        /// <summary>
        /// Adds the given <paramref name="normalizedRoleName"/> to the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to add the role to.</param>
        /// <param name="normalizedRoleName">The role to add.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task AddToRoleAsync([NotNull] TUser user, [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(normalizedRoleName, nameof(normalizedRoleName));

                if (await IsInRoleAsync(user, normalizedRoleName, cancellationToken))
                {
                    return;
                }

                var role = await _roleRepository.FirstOrDefaultAsync(r => r.NormalizedName == normalizedRoleName);

                if (role == null)
                {
                    throw new InvalidOperationException(string.Format(CultureInfo.CurrentCulture,
                        "Role {0} does not exist!", normalizedRoleName));
                }

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Roles, cancellationToken);
                user.Roles.Add(new UserRole(user.TenantId, user.Id, role.Id));
            });
        }

        /// <summary>
        /// Adds the given <paramref name="normalizedRoleName"/> to the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to add the role to.</param>
        /// <param name="normalizedRoleName">The role to add.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void AddToRole(
            [NotNull] TUser user,
            [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(normalizedRoleName, nameof(normalizedRoleName));

                if (IsInRole(user, normalizedRoleName, cancellationToken))
                {
                    return;
                }

                var role = _roleRepository.FirstOrDefault(r => r.NormalizedName == normalizedRoleName);

                if (role == null)
                {
                    throw new InvalidOperationException(string.Format(CultureInfo.CurrentCulture,
                        "Role {0} does not exist!", normalizedRoleName));
                }

                UserRepository.EnsureCollectionLoaded(user, u => u.Roles, cancellationToken);
                user.Roles.Add(new UserRole(user.TenantId, user.Id, role.Id));
            });
        }

        /// <summary>
        /// Removes the given <paramref name="normalizedRoleName"/> from the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to remove the role from.</param>
        /// <param name="normalizedRoleName">The role to remove.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task RemoveFromRoleAsync(
            [NotNull] TUser user,
            [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                if (string.IsNullOrWhiteSpace(normalizedRoleName))
                {
                    throw new ArgumentException(nameof(normalizedRoleName) + " can not be null or whitespace");
                }

                if (!await IsInRoleAsync(user, normalizedRoleName, cancellationToken))
                {
                    return;
                }

                var role = await _roleRepository.FirstOrDefaultAsync(r => r.NormalizedName == normalizedRoleName);
                if (role == null)
                {
                    return;
                }

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Roles, cancellationToken);
                user.Roles.RemoveAll(r => r.RoleId == role.Id);
            });
        }

        /// <summary>
        /// Removes the given <paramref name="normalizedRoleName"/> from the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to remove the role from.</param>
        /// <param name="normalizedRoleName">The role to remove.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void RemoveFromRole(
            [NotNull] TUser user,
            [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                if (string.IsNullOrWhiteSpace(normalizedRoleName))
                {
                    throw new ArgumentException(nameof(normalizedRoleName) + " can not be null or whitespace");
                }

                if (!IsInRole(user, normalizedRoleName, cancellationToken))
                {
                    return;
                }

                var role = _roleRepository.FirstOrDefault(r => r.NormalizedName == normalizedRoleName);
                if (role == null)
                {
                    return;
                }

                user.Roles.RemoveAll(r => r.RoleId == role.Id);
            });
        }

        /// <summary>
        /// Retrieves the roles the specified <paramref name="user"/> is a member of.
        /// </summary>
        /// <param name="user">The user whose roles should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> that contains the roles the user is a member of.</returns>
        public virtual async Task<IList<string>> GetRolesAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                var userRoles = await AsyncQueryableExecuter.ToListAsync(from userRole in _userRoleRepository.GetAll()
                    join role in _roleRepository.GetAll() on userRole.RoleId equals role.Id
                    where userRole.UserId == user.Id
                    select role.Name);

                var userOrganizationUnitRoles = await AsyncQueryableExecuter.ToListAsync(
                    from userOu in _userOrganizationUnitRepository.GetAll()
                    join roleOu in _organizationUnitRoleRepository.GetAll() on userOu.OrganizationUnitId equals roleOu
                        .OrganizationUnitId
                    join userOuRoles in _roleRepository.GetAll() on roleOu.RoleId equals userOuRoles.Id
                    where userOu.UserId == user.Id
                    select userOuRoles.Name);

                return userRoles.Union(userOrganizationUnitRoles).ToList();
            });
        }

        /// <summary>
        /// Retrieves the roles the specified <paramref name="user"/> is a member of.
        /// </summary>
        /// <param name="user">The user whose roles should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> that contains the roles the user is a member of.</returns>
        public virtual IList<string> GetRoles([NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                var userRoles = (
                    from userRole in _userRoleRepository.GetAll()
                    join role in _roleRepository.GetAll() on userRole.RoleId equals role.Id
                    where userRole.UserId == user.Id
                    select role.Name
                ).ToList();

                var userOrganizationUnitRoles = (
                    from userOu in _userOrganizationUnitRepository.GetAll()
                    join roleOu in _organizationUnitRoleRepository.GetAll() on userOu.OrganizationUnitId equals roleOu
                        .OrganizationUnitId
                    join userOuRoles in _roleRepository.GetAll() on roleOu.RoleId equals userOuRoles.Id
                    where userOu.UserId == user.Id
                    select userOuRoles.Name
                ).ToList();

                return userRoles.Union(userOrganizationUnitRoles).ToList();
            });
        }

        /// <summary>
        /// Returns a flag indicating if the specified user is a member of the give <paramref name="normalizedRoleName"/>.
        /// </summary>
        /// <param name="user">The user whose role membership should be checked.</param>
        /// <param name="normalizedRoleName">The role to check membership of</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> containing a flag indicating if the specified user is a member of the given group. If the 
        /// user is a member of the group the returned value with be true, otherwise it will be false.</returns>
        public virtual async Task<bool> IsInRoleAsync(
            [NotNull] TUser user,
            [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            if (string.IsNullOrWhiteSpace(normalizedRoleName))
            {
                throw new ArgumentException(nameof(normalizedRoleName) + " can not be null or whitespace");
            }

            return (await GetRolesAsync(user, cancellationToken)).Any(r => r.ToUpperInvariant() == normalizedRoleName);
        }

        /// <summary>
        /// Returns a flag indicating if the specified user is a member of the give <paramref name="normalizedRoleName"/>.
        /// </summary>
        /// <param name="user">The user whose role membership should be checked.</param>
        /// <param name="normalizedRoleName">The role to check membership of</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> containing a flag indicating if the specified user is a member of the given group. If the 
        /// user is a member of the group the returned value with be true, otherwise it will be false.</returns>
        public virtual bool IsInRole(
            [NotNull] TUser user,
            [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            if (string.IsNullOrWhiteSpace(normalizedRoleName))
            {
                throw new ArgumentException(nameof(normalizedRoleName) + " can not be null or whitespace");
            }

            return (GetRoles(user, cancellationToken)).Any(r => r.ToUpperInvariant() == normalizedRoleName);
        }

        /// <summary>
        /// Dispose the store
        /// </summary>
        public void Dispose()
        {
        }

        /// <summary>
        /// Get the claims associated with the specified <paramref name="user"/> as an asynchronous operation.
        /// </summary>
        /// <param name="user">The user whose claims should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> that contains the claims granted to a user.</returns>
        public virtual async Task<IList<Claim>> GetClaimsAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Claims, cancellationToken);

                return user.Claims.Select(c => new Claim(c.ClaimType, c.ClaimValue)).ToList();
            });
        }

        /// <summary>
        /// Get the claims associated with the specified <paramref name="user"/> as an asynchronous operation.
        /// </summary>
        /// <param name="user">The user whose claims should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>A <see cref="Task{TResult}"/> that contains the claims granted to a user.</returns>
        public virtual IList<Claim> GetClaims(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                UserRepository.EnsureCollectionLoaded(user, u => u.Claims, cancellationToken);

                return user.Claims.Select(c => new Claim(c.ClaimType, c.ClaimValue)).ToList();
            });
        }

        /// <summary>
        /// Adds the <paramref name="claims"/> given to the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to add the claim to.</param>
        /// <param name="claims">The claim to add to the user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task AddClaimsAsync(
            [NotNull] TUser user,
            [NotNull] IEnumerable<Claim> claims,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(claims, nameof(claims));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Claims, cancellationToken);

                foreach (var claim in claims)
                {
                    user.Claims.Add(new UserClaim(user, claim));
                }
            });
        }

        /// <summary>
        /// Adds the <paramref name="claims"/> given to the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to add the claim to.</param>
        /// <param name="claims">The claim to add to the user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void AddClaims(
            [NotNull] TUser user,
            [NotNull] IEnumerable<Claim> claims,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(claims, nameof(claims));

                UserRepository.EnsureCollectionLoaded(user, u => u.Claims, cancellationToken);

                foreach (var claim in claims)
                {
                    user.Claims.Add(new UserClaim(user, claim));
                }
            });
        }

        /// <summary>
        /// Replaces the <paramref name="claim"/> on the specified <paramref name="user"/>, with the <paramref name="newClaim"/>.
        /// </summary>
        /// <param name="user">The user to replace the claim on.</param>
        /// <param name="claim">The claim replace.</param>
        /// <param name="newClaim">The new claim replacing the <paramref name="claim"/>.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task ReplaceClaimAsync(
            [NotNull] TUser user,
            [NotNull] Claim claim,
            [NotNull] Claim newClaim,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(claim, nameof(claim));
                Check.NotNull(newClaim, nameof(newClaim));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Claims, cancellationToken);

                var userClaims = user.Claims.Where(uc => uc.ClaimValue == claim.Value && uc.ClaimType == claim.Type);
                foreach (var userClaim in userClaims)
                {
                    userClaim.ClaimType = newClaim.Type;
                    userClaim.ClaimValue = newClaim.Value;
                }
            });
        }

        /// <summary>
        /// Replaces the <paramref name="claim"/> on the specified <paramref name="user"/>, with the <paramref name="newClaim"/>.
        /// </summary>
        /// <param name="user">The user to replace the claim on.</param>
        /// <param name="claim">The claim replace.</param>
        /// <param name="newClaim">The new claim replacing the <paramref name="claim"/>.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void ReplaceClaim(
            [NotNull] TUser user,
            [NotNull] Claim claim,
            [NotNull] Claim newClaim,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(claim, nameof(claim));
                Check.NotNull(newClaim, nameof(newClaim));

                UserRepository.EnsureCollectionLoaded(user, u => u.Claims, cancellationToken);

                var userClaims = user.Claims.Where(uc => uc.ClaimValue == claim.Value && uc.ClaimType == claim.Type);
                foreach (var userClaim in userClaims)
                {
                    userClaim.ClaimType = claim.Type;
                    userClaim.ClaimValue = claim.Value;
                }
            });
        }

        /// <summary>
        /// Removes the <paramref name="claims"/> given from the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to remove the claims from.</param>
        /// <param name="claims">The claim to remove.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task RemoveClaimsAsync(
            [NotNull] TUser user,
            [NotNull] IEnumerable<Claim> claims,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(claims, nameof(claims));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Claims, cancellationToken);

                foreach (var claim in claims)
                {
                    user.Claims.RemoveAll(c => c.ClaimValue == claim.Value && c.ClaimType == claim.Type);
                }
            });
        }

        /// <summary>
        /// Removes the <paramref name="claims"/> given from the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to remove the claims from.</param>
        /// <param name="claims">The claim to remove.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void RemoveClaims(
            [NotNull] TUser user,
            [NotNull] IEnumerable<Claim> claims,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(claims, nameof(claims));

                UserRepository.EnsureCollectionLoaded(user, u => u.Claims, cancellationToken);

                foreach (var claim in claims)
                {
                    user.Claims.RemoveAll(c => c.ClaimValue == claim.Value && c.ClaimType == claim.Type);
                }
            });
        }

        /// <summary>
        /// Adds the <paramref name="login"/> given to the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to add the login to.</param>
        /// <param name="login">The login to add to the user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task AddLoginAsync(
            [NotNull] TUser user,
            [NotNull] UserLoginInfo login,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(login, nameof(login));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Logins, cancellationToken);

                user.Logins.Add(new UserLogin(user.TenantId, user.Id, login.LoginProvider, login.ProviderKey));
            });
        }

        /// <summary>
        /// Adds the <paramref name="login"/> given to the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to add the login to.</param>
        /// <param name="login">The login to add to the user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void AddLogin(
            [NotNull] TUser user,
            [NotNull] UserLoginInfo login,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(login, nameof(login));

                UserRepository.EnsureCollectionLoaded(user, u => u.Logins, cancellationToken);

                user.Logins.Add(new UserLogin(user.TenantId, user.Id, login.LoginProvider, login.ProviderKey));
            });
        }

        /// <summary>
        /// Removes the <paramref name="loginProvider"/> given from the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to remove the login from.</param>
        /// <param name="loginProvider">The login to remove from the user.</param>
        /// <param name="providerKey">The key provided by the <paramref name="loginProvider"/> to identify a user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task RemoveLoginAsync(
            [NotNull] TUser user,
            [NotNull] string loginProvider,
            [NotNull] string providerKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(loginProvider, nameof(loginProvider));
                Check.NotNull(providerKey, nameof(providerKey));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Logins, cancellationToken);

                user.Logins.RemoveAll(userLogin =>
                    userLogin.LoginProvider == loginProvider && userLogin.ProviderKey == providerKey
                );
            });
        }

        /// <summary>
        /// Removes the <paramref name="loginProvider"/> given from the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user to remove the login from.</param>
        /// <param name="loginProvider">The login to remove from the user.</param>
        /// <param name="providerKey">The key provided by the <paramref name="loginProvider"/> to identify a user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void RemoveLogin(
            [NotNull] TUser user,
            [NotNull] string loginProvider,
            [NotNull] string providerKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));
                Check.NotNull(loginProvider, nameof(loginProvider));
                Check.NotNull(providerKey, nameof(providerKey));

                UserRepository.EnsureCollectionLoaded(user, u => u.Logins, cancellationToken);

                user.Logins.RemoveAll(userLogin =>
                    userLogin.LoginProvider == loginProvider && userLogin.ProviderKey == providerKey
                );
            });
        }

        /// <summary>
        /// Retrieves the associated logins for the specified <param ref="user"/>.
        /// </summary>
        /// <param name="user">The user whose associated logins to retrieve.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> for the asynchronous operation, containing a list of <see cref="UserLoginInfo"/> for the specified <paramref name="user"/>, if any.
        /// </returns>
        public virtual async Task<IList<UserLoginInfo>> GetLoginsAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Logins, cancellationToken);

                return user.Logins.Select(l => new UserLoginInfo(l.LoginProvider, l.ProviderKey, l.LoginProvider))
                    .ToList();
            });
        }

        /// <summary>
        /// Retrieves the associated logins for the specified <param ref="user"/>.
        /// </summary>
        /// <param name="user">The user whose associated logins to retrieve.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> for the asynchronous operation, containing a list of <see cref="UserLoginInfo"/> for the specified <paramref name="user"/>, if any.
        /// </returns>
        public virtual IList<UserLoginInfo> GetLogins(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                UserRepository.EnsureCollectionLoaded(user, u => u.Logins, cancellationToken);

                return user.Logins
                    .Select(l => new UserLoginInfo(l.LoginProvider, l.ProviderKey, l.LoginProvider))
                    .ToList();
            });
        }

        /// <summary>
        /// Retrieves the user associated with the specified login provider and login provider key..
        /// </summary>
        /// <param name="loginProvider">The login provider who provided the <paramref name="providerKey"/>.</param>
        /// <param name="providerKey">The key provided by the <paramref name="loginProvider"/> to identify a user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> for the asynchronous operation, containing the user, if any which matched the specified login provider and key.
        /// </returns>
        public virtual async Task<TUser> FindByLoginAsync(
            [NotNull] string loginProvider,
            [NotNull] string providerKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(loginProvider, nameof(loginProvider));
                Check.NotNull(providerKey, nameof(providerKey));

                var query = from userLogin in _userLoginRepository.GetAll()
                    join user in UserRepository.GetAll() on userLogin.UserId equals user.Id
                    where userLogin.LoginProvider == loginProvider &&
                          userLogin.ProviderKey == providerKey &&
                          userLogin.TenantId == AbpSession.TenantId
                    select user;

                return await AsyncQueryableExecuter.FirstOrDefaultAsync(query);
            });
        }

        /// <summary>
        /// Retrieves the user associated with the specified login provider and login provider key..
        /// </summary>
        /// <param name="loginProvider">The login provider who provided the <paramref name="providerKey"/>.</param>
        /// <param name="providerKey">The key provided by the <paramref name="loginProvider"/> to identify a user.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> for the asynchronous operation, containing the user, if any which matched the specified login provider and key.
        /// </returns>
        public virtual TUser FindByLogin(
            [NotNull] string loginProvider,
            [NotNull] string providerKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(loginProvider, nameof(loginProvider));
                Check.NotNull(providerKey, nameof(providerKey));

                var query = from userLogin in _userLoginRepository.GetAll()
                    join user in UserRepository.GetAll() on userLogin.UserId equals user.Id
                    where userLogin.LoginProvider == loginProvider &&
                          userLogin.ProviderKey == providerKey &&
                          userLogin.TenantId == AbpSession.TenantId
                    select user;

                return query.FirstOrDefault();
            });
        }

        /// <summary>
        /// Gets a flag indicating whether the email address for the specified <paramref name="user"/> has been verified, true if the email address is verified otherwise
        /// false.
        /// </summary>
        /// <param name="user">The user whose email confirmation status should be returned.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The task object containing the results of the asynchronous operation, a flag indicating whether the email address for the specified <paramref name="user"/>
        /// has been confirmed or not.
        /// </returns>
        public virtual Task<bool> GetEmailConfirmedAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.IsEmailConfirmed);
        }

        /// <summary>
        /// Gets a flag indicating whether the email address for the specified <paramref name="user"/> has been verified, true if the email address is verified otherwise
        /// false.
        /// </summary>
        /// <param name="user">The user whose email confirmation status should be returned.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The task object containing the results of the asynchronous operation, a flag indicating whether the email address for the specified <paramref name="user"/>
        /// has been confirmed or not.
        /// </returns>
        public virtual bool GetEmailConfirmed(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.IsEmailConfirmed;
        }

        /// <summary>
        /// Sets the flag indicating whether the specified <paramref name="user"/>'s email address has been confirmed or not.
        /// </summary>
        /// <param name="user">The user whose email confirmation status should be set.</param>
        /// <param name="confirmed">A flag indicating if the email address has been confirmed, true if the address is confirmed otherwise false.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object representing the asynchronous operation.</returns>
        public virtual Task SetEmailConfirmedAsync(
            [NotNull] TUser user,
            bool confirmed,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsEmailConfirmed = confirmed;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the flag indicating whether the specified <paramref name="user"/>'s email address has been confirmed or not.
        /// </summary>
        /// <param name="user">The user whose email confirmation status should be set.</param>
        /// <param name="confirmed">A flag indicating if the email address has been confirmed, true if the address is confirmed otherwise false.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object representing the asynchronous operation.</returns>
        public virtual void SetEmailConfirmed(
            [NotNull] TUser user,
            bool confirmed,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsEmailConfirmed = confirmed;
        }

        /// <summary>
        /// Sets the <paramref name="email"/> address for a <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email should be set.</param>
        /// <param name="email">The email to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object representing the asynchronous operation.</returns>
        public virtual Task SetEmailAsync(
            [NotNull] TUser user,
            string email,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.EmailAddress = email;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the <paramref name="email"/> address for a <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email should be set.</param>
        /// <param name="email">The email to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object representing the asynchronous operation.</returns>
        public virtual void SetEmail(
            [NotNull] TUser user,
            string email,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.EmailAddress = email;
        }

        /// <summary>
        /// Gets the email address for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email should be returned.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object containing the results of the asynchronous operation, the email address for the specified <paramref name="user"/>.</returns>
        public virtual Task<string> GetEmailAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.EmailAddress);
        }

        /// <summary>
        /// Gets the email address for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email should be returned.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object containing the results of the asynchronous operation, the email address for the specified <paramref name="user"/>.</returns>
        public virtual string GetEmail(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.EmailAddress;
        }

        /// <summary>
        /// Returns the normalized email for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email address to retrieve.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The task object containing the results of the asynchronous lookup operation, the normalized email address if any associated with the specified user.
        /// </returns>
        public virtual Task<string> GetNormalizedEmailAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.NormalizedEmailAddress);
        }

        /// <summary>
        /// Returns the normalized email for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email address to retrieve.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The task object containing the results of the asynchronous lookup operation, the normalized email address if any associated with the specified user.
        /// </returns>
        public virtual string GetNormalizedEmail(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.NormalizedEmailAddress;
        }

        /// <summary>
        /// Sets the normalized email for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email address to set.</param>
        /// <param name="normalizedEmail">The normalized email to set for the specified <paramref name="user"/>.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object representing the asynchronous operation.</returns>
        public virtual Task SetNormalizedEmailAsync(
            [NotNull] TUser user,
            string normalizedEmail,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.NormalizedEmailAddress = normalizedEmail;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the normalized email for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose email address to set.</param>
        /// <param name="normalizedEmail">The normalized email to set for the specified <paramref name="user"/>.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The task object representing the asynchronous operation.</returns>
        public virtual void SetNormalizedEmail(
            [NotNull] TUser user,
            string normalizedEmail,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.NormalizedEmailAddress = normalizedEmail;
        }

        /// <summary>
        /// Gets the user, if any, associated with the specified, normalized email address.
        /// </summary>
        /// <param name="normalizedEmail">The normalized email address to return the user for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The task object containing the results of the asynchronous lookup operation, the user if any associated with the specified normalized email address.
        /// </returns>
        public virtual async Task<TUser> FindByEmailAsync(
            string normalizedEmail,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                return await UserRepository.FirstOrDefaultAsync(u => u.NormalizedEmailAddress == normalizedEmail);
            });
        }

        /// <summary>
        /// Gets the user, if any, associated with the specified, normalized email address.
        /// </summary>
        /// <param name="normalizedEmail">The normalized email address to return the user for.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The task object containing the results of the asynchronous lookup operation, the user if any associated with the specified normalized email address.
        /// </returns>
        public virtual TUser FindByEmail(
            string normalizedEmail,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                return UserRepository.FirstOrDefault(u => u.NormalizedEmailAddress == normalizedEmail);
            });
        }

        /// <summary>
        /// Gets the last <see cref="DateTimeOffset"/> a user's last lockout expired, if any.
        /// Any time in the past should be indicates a user is not locked out.
        /// </summary>
        /// <param name="user">The user whose lockout date should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// A <see cref="Task{TResult}"/> that represents the result of the asynchronous query, a <see cref="DateTimeOffset"/> containing the last time
        /// a user's lockout expired, if any.
        /// </returns>
        public virtual Task<DateTimeOffset?> GetLockoutEndDateAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            if (!user.LockoutEndDateUtc.HasValue)
            {
                return Task.FromResult<DateTimeOffset?>(null);
            }

            var lockoutEndDate = DateTime.SpecifyKind(user.LockoutEndDateUtc.Value, DateTimeKind.Utc);

            return Task.FromResult<DateTimeOffset?>(new DateTimeOffset(lockoutEndDate));
        }

        /// <summary>
        /// Gets the last <see cref="DateTimeOffset"/> a user's last lockout expired, if any.
        /// Any time in the past should be indicates a user is not locked out.
        /// </summary>
        /// <param name="user">The user whose lockout date should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// A <see cref="Task{TResult}"/> that represents the result of the asynchronous query, a <see cref="DateTimeOffset"/> containing the last time
        /// a user's lockout expired, if any.
        /// </returns>
        public virtual DateTimeOffset? GetLockoutEndDate(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            if (!user.LockoutEndDateUtc.HasValue)
            {
                return (DateTimeOffset?) null;
            }

            var lockoutEndDate = DateTime.SpecifyKind(user.LockoutEndDateUtc.Value, DateTimeKind.Utc);

            return new DateTimeOffset(lockoutEndDate);
        }

        /// <summary>
        /// Locks out a user until the specified end date has passed. Setting a end date in the past immediately unlocks a user.
        /// </summary>
        /// <param name="user">The user whose lockout date should be set.</param>
        /// <param name="lockoutEnd">The <see cref="DateTimeOffset"/> after which the <paramref name="user"/>'s lockout should end.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetLockoutEndDateAsync(
            [NotNull] TUser user,
            DateTimeOffset? lockoutEnd,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.LockoutEndDateUtc = lockoutEnd?.UtcDateTime;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Locks out a user until the specified end date has passed. Setting a end date in the past immediately unlocks a user.
        /// </summary>
        /// <param name="user">The user whose lockout date should be set.</param>
        /// <param name="lockoutEnd">The <see cref="DateTimeOffset"/> after which the <paramref name="user"/>'s lockout should end.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetLockoutEndDate(
            [NotNull] TUser user,
            DateTimeOffset? lockoutEnd,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.LockoutEndDateUtc = lockoutEnd?.UtcDateTime;
        }

        /// <summary>
        /// Records that a failed access has occurred, incrementing the failed access count.
        /// </summary>
        /// <param name="user">The user whose cancellation count should be incremented.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the incremented failed access count.</returns>
        public virtual Task<int> IncrementAccessFailedCountAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.AccessFailedCount++;

            return Task.FromResult(user.AccessFailedCount);
        }

        /// <summary>
        /// Records that a failed access has occurred, incrementing the failed access count.
        /// </summary>
        /// <param name="user">The user whose cancellation count should be incremented.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the incremented failed access count.</returns>
        public virtual int IncrementAccessFailedCount(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.AccessFailedCount++;

            return user.AccessFailedCount;
        }

        /// <summary>
        /// Resets a user's failed access count.
        /// </summary>
        /// <param name="user">The user whose failed access count should be reset.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        /// <remarks>This is typically called after the account is successfully accessed.</remarks>
        public virtual Task ResetAccessFailedCountAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.AccessFailedCount = 0;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Resets a user's failed access count.
        /// </summary>
        /// <param name="user">The user whose failed access count should be reset.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        /// <remarks>This is typically called after the account is successfully accessed.</remarks>
        public virtual void ResetAccessFailedCount(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.AccessFailedCount = 0;
        }

        /// <summary>
        /// Retrieves the current failed access count for the specified <paramref name="user"/>..
        /// </summary>
        /// <param name="user">The user whose failed access count should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the failed access count.</returns>
        public virtual Task<int> GetAccessFailedCountAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.AccessFailedCount);
        }

        /// <summary>
        /// Retrieves the current failed access count for the specified <paramref name="user"/>..
        /// </summary>
        /// <param name="user">The user whose failed access count should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the failed access count.</returns>
        public virtual int GetAccessFailedCount(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.AccessFailedCount;
        }

        /// <summary>
        /// Retrieves a flag indicating whether user lockout can enabled for the specified user.
        /// </summary>
        /// <param name="user">The user whose ability to be locked out should be returned.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, true if a user can be locked out, otherwise false.
        /// </returns>
        public virtual Task<bool> GetLockoutEnabledAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.IsLockoutEnabled);
        }

        /// <summary>
        /// Retrieves a flag indicating whether user lockout can enabled for the specified user.
        /// </summary>
        /// <param name="user">The user whose ability to be locked out should be returned.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, true if a user can be locked out, otherwise false.
        /// </returns>
        public virtual bool GetLockoutEnabled(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.IsLockoutEnabled;
        }

        /// <summary>
        /// Set the flag indicating if the specified <paramref name="user"/> can be locked out..
        /// </summary>
        /// <param name="user">The user whose ability to be locked out should be set.</param>
        /// <param name="enabled">A flag indicating if lock out can be enabled for the specified <paramref name="user"/>.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetLockoutEnabledAsync(
            [NotNull] TUser user,
            bool enabled,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsLockoutEnabled = enabled;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Set the flag indicating if the specified <paramref name="user"/> can be locked out..
        /// </summary>
        /// <param name="user">The user whose ability to be locked out should be set.</param>
        /// <param name="enabled">A flag indicating if lock out can be enabled for the specified <paramref name="user"/>.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetLockoutEnabled(
            [NotNull] TUser user,
            bool enabled,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsLockoutEnabled = enabled;
        }

        /// <summary>
        /// Sets the telephone number for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose telephone number should be set.</param>
        /// <param name="phoneNumber">The telephone number to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetPhoneNumberAsync(
            [NotNull] TUser user,
            string phoneNumber,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.PhoneNumber = phoneNumber;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the telephone number for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose telephone number should be set.</param>
        /// <param name="phoneNumber">The telephone number to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetPhoneNumber(
            [NotNull] TUser user,
            string phoneNumber,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.PhoneNumber = phoneNumber;
        }

        /// <summary>
        /// Gets the telephone number, if any, for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose telephone number should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the user's telephone number, if any.</returns>
        public virtual Task<string> GetPhoneNumberAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.PhoneNumber);
        }

        /// <summary>
        /// Gets the telephone number, if any, for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose telephone number should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the user's telephone number, if any.</returns>
        public virtual string GetPhoneNumber(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.PhoneNumber;
        }

        /// <summary>
        /// Gets a flag indicating whether the specified <paramref name="user"/>'s telephone number has been confirmed.
        /// </summary>
        /// <param name="user">The user to return a flag for, indicating whether their telephone number is confirmed.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, returning true if the specified <paramref name="user"/> has a confirmed
        /// telephone number otherwise false.
        /// </returns>
        public virtual Task<bool> GetPhoneNumberConfirmedAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.IsPhoneNumberConfirmed);
        }

        /// <summary>
        /// Gets a flag indicating whether the specified <paramref name="user"/>'s telephone number has been confirmed.
        /// </summary>
        /// <param name="user">The user to return a flag for, indicating whether their telephone number is confirmed.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, returning true if the specified <paramref name="user"/> has a confirmed
        /// telephone number otherwise false.
        /// </returns>
        public virtual bool GetPhoneNumberConfirmed(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.IsPhoneNumberConfirmed;
        }

        /// <summary>
        /// Sets a flag indicating if the specified <paramref name="user"/>'s phone number has been confirmed..
        /// </summary>
        /// <param name="user">The user whose telephone number confirmation status should be set.</param>
        /// <param name="confirmed">A flag indicating whether the user's telephone number has been confirmed.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetPhoneNumberConfirmedAsync(
            [NotNull] TUser user,
            bool confirmed,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsPhoneNumberConfirmed = confirmed;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets a flag indicating if the specified <paramref name="user"/>'s phone number has been confirmed..
        /// </summary>
        /// <param name="user">The user whose telephone number confirmation status should be set.</param>
        /// <param name="confirmed">A flag indicating whether the user's telephone number has been confirmed.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetPhoneNumberConfirmed(
            [NotNull] TUser user,
            bool confirmed,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsPhoneNumberConfirmed = confirmed;
        }

        /// <summary>
        /// Sets the provided security <paramref name="stamp"/> for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose security stamp should be set.</param>
        /// <param name="stamp">The security stamp to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetSecurityStampAsync(
            [NotNull] TUser user,
            string stamp,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.SecurityStamp = stamp;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets the provided security <paramref name="stamp"/> for the specified <paramref name="user"/>.
        /// </summary>
        /// <param name="user">The user whose security stamp should be set.</param>
        /// <param name="stamp">The security stamp to set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetSecurityStamp(
            [NotNull] TUser user,
            string stamp,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.SecurityStamp = stamp;
        }

        /// <summary>
        /// Get the security stamp for the specified <paramref name="user" />.
        /// </summary>
        /// <param name="user">The user whose security stamp should be set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the security stamp for the specified <paramref name="user"/>.</returns>
        public virtual Task<string> GetSecurityStampAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.SecurityStamp);
        }

        /// <summary>
        /// Get the security stamp for the specified <paramref name="user" />.
        /// </summary>
        /// <param name="user">The user whose security stamp should be set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation, containing the security stamp for the specified <paramref name="user"/>.</returns>
        public virtual string GetSecurityStamp(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.SecurityStamp;
        }

        /// <summary>
        /// Sets a flag indicating whether the specified <paramref name="user"/> has two factor authentication enabled or not,
        /// as an asynchronous operation.
        /// </summary>
        /// <param name="user">The user whose two factor authentication enabled status should be set.</param>
        /// <param name="enabled">A flag indicating whether the specified <paramref name="user"/> has two factor authentication enabled.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual Task SetTwoFactorEnabledAsync(
            [NotNull] TUser user,
            bool enabled,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsTwoFactorEnabled = enabled;

            return Task.CompletedTask;
        }

        /// <summary>
        /// Sets a flag indicating whether the specified <paramref name="user"/> has two factor authentication enabled or not,
        /// as an asynchronous operation.
        /// </summary>
        /// <param name="user">The user whose two factor authentication enabled status should be set.</param>
        /// <param name="enabled">A flag indicating whether the specified <paramref name="user"/> has two factor authentication enabled.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetTwoFactorEnabled(
            [NotNull] TUser user,
            bool enabled,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            user.IsTwoFactorEnabled = enabled;
        }

        /// <summary>
        /// Returns a flag indicating whether the specified <paramref name="user"/> has two factor authentication enabled or not,
        /// as an asynchronous operation.
        /// </summary>
        /// <param name="user">The user whose two factor authentication enabled status should be set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, containing a flag indicating whether the specified 
        /// <paramref name="user"/> has two factor authentication enabled or not.
        /// </returns>
        public virtual Task<bool> GetTwoFactorEnabledAsync(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return Task.FromResult(user.IsTwoFactorEnabled);
        }

        /// <summary>
        /// Returns a flag indicating whether the specified <paramref name="user"/> has two factor authentication enabled or not,
        /// as an asynchronous operation.
        /// </summary>
        /// <param name="user">The user whose two factor authentication enabled status should be set.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> that represents the asynchronous operation, containing a flag indicating whether the specified 
        /// <paramref name="user"/> has two factor authentication enabled or not.
        /// </returns>
        public virtual bool GetTwoFactorEnabled(
            [NotNull] TUser user,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            cancellationToken.ThrowIfCancellationRequested();

            Check.NotNull(user, nameof(user));

            return user.IsTwoFactorEnabled;
        }

        /// <summary>
        /// Retrieves all users with the specified claim.
        /// </summary>
        /// <param name="claim">The claim whose users should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> contains a list of users, if any, that contain the specified claim. 
        /// </returns>
        public virtual async Task<IList<TUser>> GetUsersForClaimAsync(
            [NotNull] Claim claim,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(claim, nameof(claim));

                var query = from userclaims in _userClaimRepository.GetAll()
                    join user in UserRepository.GetAll() on userclaims.UserId equals user.Id
                    where userclaims.ClaimValue == claim.Value && userclaims.ClaimType == claim.Type &&
                          userclaims.TenantId == AbpSession.TenantId
                    select user;

                return await AsyncQueryableExecuter.ToListAsync(query);
            });
        }

        /// <summary>
        /// Retrieves all users with the specified claim.
        /// </summary>
        /// <param name="claim">The claim whose users should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> contains a list of users, if any, that contain the specified claim. 
        /// </returns>
        public virtual IList<TUser> GetUsersForClaim(
            [NotNull] Claim claim,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(claim, nameof(claim));

                var query = from userclaims in _userClaimRepository.GetAll()
                    join user in UserRepository.GetAll() on userclaims.UserId equals user.Id
                    where userclaims.ClaimValue == claim.Value && userclaims.ClaimType == claim.Type &&
                          userclaims.TenantId == AbpSession.TenantId
                    select user;

                return query.ToList();
            });
        }

        /// <summary>
        /// Retrieves all users in the specified role.
        /// </summary>
        /// <param name="normalizedRoleName">The role whose users should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> contains a list of users, if any, that are in the specified role. 
        /// </returns>
        public virtual async Task<IList<TUser>> GetUsersInRoleAsync(
            [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                if (string.IsNullOrEmpty(normalizedRoleName))
                {
                    throw new ArgumentNullException(nameof(normalizedRoleName));
                }

                var role = await _roleRepository.FirstOrDefaultAsync(r => r.NormalizedName == normalizedRoleName);

                if (role == null)
                {
                    return new List<TUser>();
                }

                var query = from userrole in _userRoleRepository.GetAll()
                    join user in UserRepository.GetAll() on userrole.UserId equals user.Id
                    where userrole.RoleId.Equals(role.Id)
                    select user;

                return await AsyncQueryableExecuter.ToListAsync(query);
            });
        }

        /// <summary>
        /// Retrieves all users in the specified role.
        /// </summary>
        /// <param name="normalizedRoleName">The role whose users should be retrieved.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>
        /// The <see cref="Task"/> contains a list of users, if any, that are in the specified role. 
        /// </returns>
        public virtual IList<TUser> GetUsersInRole(
            [NotNull] string normalizedRoleName,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                if (string.IsNullOrEmpty(normalizedRoleName))
                {
                    throw new ArgumentNullException(nameof(normalizedRoleName));
                }

                var role = _roleRepository.FirstOrDefault(r => r.NormalizedName == normalizedRoleName);

                if (role == null)
                {
                    return new List<TUser>();
                }

                var query = from userrole in _userRoleRepository.GetAll()
                    join user in UserRepository.GetAll() on userrole.UserId equals user.Id
                    where userrole.RoleId.Equals(role.Id)
                    select user;

                return query.ToList();
            });
        }

        /// <summary>
        /// Sets the token value for a particular user.
        /// </summary>
        /// <param name="user">The user.</param>
        /// <param name="loginProvider">The authentication provider for the token.</param>
        /// <param name="name">The name of the token.</param>
        /// <param name="value">The value of the token.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task SetTokenAsync(
            [NotNull] TUser user,
            string loginProvider,
            string name,
            string value,
            CancellationToken cancellationToken)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Tokens, cancellationToken);

                var token = user.Tokens.FirstOrDefault(t => t.LoginProvider == loginProvider && t.Name == name);
                if (token == null)
                {
                    user.Tokens.Add(new UserToken(user, loginProvider, name, value));
                }
                else
                {
                    token.Value = value;
                }
            });
        }

        /// <summary>
        /// Sets the token value for a particular user.
        /// </summary>
        /// <param name="user">The user.</param>
        /// <param name="loginProvider">The authentication provider for the token.</param>
        /// <param name="name">The name of the token.</param>
        /// <param name="value">The value of the token.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void SetToken(
            [NotNull] TUser user,
            string loginProvider,
            string name,
            string value,
            CancellationToken cancellationToken)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();

                Check.NotNull(user, nameof(user));

                UserRepository.EnsureCollectionLoaded(user, u => u.Tokens, cancellationToken);

                var token = user.Tokens.FirstOrDefault(t => t.LoginProvider == loginProvider && t.Name == name);
                if (token == null)
                {
                    user.Tokens.Add(new UserToken(user, loginProvider, name, value));
                }
                else
                {
                    token.Value = value;
                }
            });
        }

        /// <summary>
        /// Deletes a token for a user.
        /// </summary>
        /// <param name="user">The user.</param>
        /// <param name="loginProvider">The authentication provider for the token.</param>
        /// <param name="name">The name of the token.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task RemoveTokenAsync(
            TUser user,
            string loginProvider,
            string name,
            CancellationToken cancellationToken)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Tokens, cancellationToken);
                user.Tokens.RemoveAll(t => t.LoginProvider == loginProvider && t.Name == name);
            });
        }

        /// <summary>
        /// Deletes a token for a user.
        /// </summary>
        /// <param name="user">The user.</param>
        /// <param name="loginProvider">The authentication provider for the token.</param>
        /// <param name="name">The name of the token.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual void RemoveToken(
            TUser user,
            string loginProvider,
            string name,
            CancellationToken cancellationToken)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                UserRepository.EnsureCollectionLoaded(user, u => u.Tokens, cancellationToken);
                user.Tokens.RemoveAll(t => t.LoginProvider == loginProvider && t.Name == name);
            });
        }

        /// <summary>
        /// Returns the token value.
        /// </summary>
        /// <param name="user">The user.</param>
        /// <param name="loginProvider">The authentication provider for the token.</param>
        /// <param name="name">The name of the token.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual async Task<string> GetTokenAsync(TUser user, string loginProvider, string name,
            CancellationToken cancellationToken)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Tokens, cancellationToken);
                return user.Tokens.FirstOrDefault(t => t.LoginProvider == loginProvider && t.Name == name)?.Value;
            });
        }

        /// <summary>
        /// Returns the token value.
        /// </summary>
        /// <param name="user">The user.</param>
        /// <param name="loginProvider">The authentication provider for the token.</param>
        /// <param name="name">The name of the token.</param>
        /// <param name="cancellationToken">The <see cref="CancellationToken"/> used to propagate notifications that the operation should be canceled.</param>
        /// <returns>The <see cref="Task"/> that represents the asynchronous operation.</returns>
        public virtual string GetToken(TUser user, string loginProvider, string name, CancellationToken cancellationToken)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                UserRepository.EnsureCollectionLoaded(user, u => u.Tokens, cancellationToken);
                return user.Tokens.FirstOrDefault(t => t.LoginProvider == loginProvider && t.Name == name)?.Value;
            });
        }

        /// <summary>
        /// Tries to find a user with user name or email address in current tenant.
        /// </summary>
        /// <param name="userNameOrEmailAddress">User name or email address</param>
        /// <returns>User or null</returns>
        public virtual async Task<TUser> FindByNameOrEmailAsync(string userNameOrEmailAddress)
        {
            var normalizedUserNameOrEmailAddress = NormalizeKey(userNameOrEmailAddress);

            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                return await UserRepository.FirstOrDefaultAsync(
                    user => (user.NormalizedUserName == normalizedUserNameOrEmailAddress ||
                             user.NormalizedEmailAddress == normalizedUserNameOrEmailAddress)
                );
            });
        }

        /// <summary>
        /// Tries to find a user with user name or email address in current tenant.
        /// </summary>
        /// <param name="userNameOrEmailAddress">User name or email address</param>
        /// <returns>User or null</returns>
        public virtual TUser FindByNameOrEmail(string userNameOrEmailAddress)
        {
            var normalizedUserNameOrEmailAddress = NormalizeKey(userNameOrEmailAddress);

            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                return UserRepository.FirstOrDefault(
                    user => (user.NormalizedUserName == normalizedUserNameOrEmailAddress ||
                             user.NormalizedEmailAddress == normalizedUserNameOrEmailAddress)
                );
            });
        }

        /// <summary>
        /// Tries to find a user with user name or email address in given tenant.
        /// </summary>
        /// <param name="tenantId">Tenant Id</param>
        /// <param name="userNameOrEmailAddress">User name or email address</param>
        /// <returns>User or null</returns>
        public virtual async Task<TUser> FindByNameOrEmailAsync(string tenantId, string userNameOrEmailAddress)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    return await FindByNameOrEmailAsync(userNameOrEmailAddress);
                }
            });
        }

        /// <summary>
        /// Tries to find a user with user name or email address in given tenant.
        /// </summary>
        /// <param name="tenantId">Tenant Id</param>
        /// <param name="userNameOrEmailAddress">User name or email address</param>
        /// <returns>User or null</returns>
        public virtual TUser FindByNameOrEmail(string tenantId, string userNameOrEmailAddress)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    return FindByNameOrEmail(userNameOrEmailAddress);
                }
            });
        }

        public virtual async Task<TUser> FindAsync(UserLoginInfo login)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                var userLogin = await _userLoginRepository.FirstOrDefaultAsync(
                    ul => ul.LoginProvider == login.LoginProvider && ul.ProviderKey == login.ProviderKey
                );

                if (userLogin == null)
                {
                    return null;
                }

                return await UserRepository.FirstOrDefaultAsync(u => u.Id == userLogin.UserId);
            });
        }

        public virtual TUser Find(UserLoginInfo login)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                var userLogin = _userLoginRepository.FirstOrDefault(
                    ul => ul.LoginProvider == login.LoginProvider && ul.ProviderKey == login.ProviderKey
                );

                if (userLogin == null)
                {
                    return null;
                }

                return UserRepository.FirstOrDefault(u => u.Id == userLogin.UserId);
            });
        }

        public virtual async Task<List<TUser>> FindAllAsync(UserLoginInfo login)
        {
            var result = _unitOfWorkManager.WithUnitOfWork(() =>
            {
                var query = from userLogin in _userLoginRepository.GetAll()
                    join user in UserRepository.GetAll() on userLogin.UserId equals user.Id
                    where userLogin.LoginProvider == login.LoginProvider && userLogin.ProviderKey == login.ProviderKey
                    select user;

                return query.ToList();
            });

            return await Task.FromResult(result);
        }

        public virtual List<TUser> FindAll(UserLoginInfo login)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                var query = from userLogin in _userLoginRepository.GetAll()
                    join user in UserRepository.GetAll() on userLogin.UserId equals user.Id
                    where userLogin.LoginProvider == login.LoginProvider && userLogin.ProviderKey == login.ProviderKey
                    select user;

                return query.ToList();
            });
        }

        public virtual async Task<TUser> FindAsync(string tenantId, UserLoginInfo login)
        {
            var result = _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    var query = from userLogin in _userLoginRepository.GetAll()
                        join user in UserRepository.GetAll() on userLogin.UserId equals user.Id
                        where userLogin.LoginProvider == login.LoginProvider &&
                              userLogin.ProviderKey == login.ProviderKey
                        select user;

                    return query.FirstOrDefault();
                }
            });

            return await Task.FromResult(result);
        }

        public virtual TUser Find(string tenantId, UserLoginInfo login)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                using (_unitOfWorkManager.Current.SetTenantId(tenantId))
                {
                    var query = from userLogin in _userLoginRepository.GetAll()
                        join user in UserRepository.GetAll() on userLogin.UserId equals user.Id
                        where userLogin.LoginProvider == login.LoginProvider &&
                              userLogin.ProviderKey == login.ProviderKey
                        select user;

                    return query.FirstOrDefault();
                }
            });
        }

        public virtual async Task<string> GetUserNameFromDatabaseAsync(string userId)
        {
            using (var uow = _unitOfWorkManager.Begin(new UnitOfWorkOptions
                   {
                       Scope = TransactionScopeOption.Suppress
                   }))
            {
                var user = await UserRepository.GetAsync(userId);
                await uow.CompleteAsync();
                return user.UserName;
            }
        }

        public virtual string GetUserNameFromDatabase(string userId)
        {
            using (var uow = _unitOfWorkManager.Begin(new UnitOfWorkOptions
                   {
                       Scope = TransactionScopeOption.Suppress
                   }))
            {
                var user = UserRepository.Get(userId);
                uow.Complete();
                return user.UserName;
            }
        }

        public virtual async Task AddPermissionAsync(TUser user, PermissionGrantInfo permissionGrant)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                if (await HasPermissionAsync(user.Id, permissionGrant))
                {
                    return;
                }

                await _userPermissionSettingRepository.InsertAsync(
                    new UserPermissionSetting
                    {
                        TenantId = user.TenantId,
                        UserId = user.Id,
                        Name = permissionGrant.Name,
                        IsGranted = permissionGrant.IsGranted
                    }
                );
            });
        }

        public virtual void AddPermission(TUser user, PermissionGrantInfo permissionGrant)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                if (HasPermission(user.Id, permissionGrant))
                {
                    return;
                }

                _userPermissionSettingRepository.Insert(
                    new UserPermissionSetting
                    {
                        TenantId = user.TenantId,
                        UserId = user.Id,
                        Name = permissionGrant.Name,
                        IsGranted = permissionGrant.IsGranted
                    }
                );
            });
        }

        public virtual async Task RemovePermissionAsync(TUser user, PermissionGrantInfo permissionGrant)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await _userPermissionSettingRepository.DeleteAsync(
                    permissionSetting => permissionSetting.UserId == user.Id &&
                                         permissionSetting.Name == permissionGrant.Name &&
                                         permissionSetting.IsGranted == permissionGrant.IsGranted
                );
            });
        }

        public virtual void RemovePermission(TUser user, PermissionGrantInfo permissionGrant)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                _userPermissionSettingRepository.Delete(
                    permissionSetting => permissionSetting.UserId == user.Id &&
                                         permissionSetting.Name == permissionGrant.Name &&
                                         permissionSetting.IsGranted == permissionGrant.IsGranted
                );
            });
        }

        public virtual async Task<IList<PermissionGrantInfo>> GetPermissionsAsync(string userId)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                return (await _userPermissionSettingRepository.GetAllListAsync(p => p.UserId == userId))
                    .Select(p => new PermissionGrantInfo(p.Name, p.IsGranted))
                    .ToList();
            });
        }

        public virtual IList<PermissionGrantInfo> GetPermissions(string userId)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                return (_userPermissionSettingRepository.GetAllList(p => p.UserId == userId))
                    .Select(p => new PermissionGrantInfo(p.Name, p.IsGranted))
                    .ToList();
            });
        }

        public virtual async Task<bool> HasPermissionAsync(string userId, PermissionGrantInfo permissionGrant)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                return await _userPermissionSettingRepository.FirstOrDefaultAsync(
                    p => p.UserId == userId &&
                         p.Name == permissionGrant.Name &&
                         p.IsGranted == permissionGrant.IsGranted
                ) != null;
            });
        }

        public virtual bool HasPermission(string userId, PermissionGrantInfo permissionGrant)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                return _userPermissionSettingRepository.FirstOrDefault(
                    p => p.UserId == userId &&
                         p.Name == permissionGrant.Name &&
                         p.IsGranted == permissionGrant.IsGranted
                ) != null;
            });
        }

        public virtual async Task RemoveAllPermissionSettingsAsync(TUser user)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                await _userPermissionSettingRepository.DeleteAsync(s => s.UserId == user.Id);
            });
        }

        public virtual void RemoveAllPermissionSettings(TUser user)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                _userPermissionSettingRepository.Delete(s => s.UserId == user.Id);
            });
        }

        private const string InternalLoginProvider = "[AspNetUserStore]";
        private const string AuthenticatorKeyTokenName = "AuthenticatorKey";
        private const string TokenValidityKeyProvider = "TokenValidityKeyProvider";

        public virtual async Task SetAuthenticatorKeyAsync(TUser user, string key, CancellationToken cancellationToken)
        {
            await SetTokenAsync(user, InternalLoginProvider, AuthenticatorKeyTokenName, key, cancellationToken);
        }

        public virtual void SetAuthenticatorKey(TUser user, string key, CancellationToken cancellationToken)
        {
            SetToken(user, InternalLoginProvider, AuthenticatorKeyTokenName, key, cancellationToken);
        }

        public virtual async Task<string> GetAuthenticatorKeyAsync(TUser user, CancellationToken cancellationToken)
        {
            return await GetTokenAsync(user, InternalLoginProvider, AuthenticatorKeyTokenName, cancellationToken);
        }

        public virtual string GetAuthenticatorKey(TUser user, CancellationToken cancellationToken)
        {
            return GetToken(user, InternalLoginProvider, AuthenticatorKeyTokenName, cancellationToken);
        }

        public virtual async Task AddTokenValidityKeyAsync(
            [NotNull] TUser user,
            string tokenValidityKey,
            DateTime expireDate,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Tokens, cancellationToken);
                user.Tokens.Add(new UserToken(user, TokenValidityKeyProvider, tokenValidityKey, null, expireDate));
            });
        }

        public virtual void AddTokenValidityKey(
            [NotNull] TUser user,
            string tokenValidityKey,
            DateTime expireDate,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                UserRepository.EnsureCollectionLoaded(user, u => u.Tokens, cancellationToken);
                user.Tokens.Add(new UserToken(user, TokenValidityKeyProvider, tokenValidityKey, null, expireDate));
            });
        }

        public virtual async Task AddTokenValidityKeyAsync(
            UserIdentifier user,
            string tokenValidityKey,
            DateTime expireDate,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                await _userTokenRepository.InsertAsync(
                    new UserToken(
                        user,
                        TokenValidityKeyProvider,
                        tokenValidityKey,
                        null,
                        expireDate
                    ));
            });
        }

        public virtual void AddTokenValidityKey(
            UserIdentifier user,
            string tokenValidityKey,
            DateTime expireDate,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                _userTokenRepository.Insert(
                    new UserToken(
                        user,
                        TokenValidityKeyProvider,
                        tokenValidityKey,
                        null,
                        expireDate
                    ));
            });
        }

        public virtual async Task<bool> IsTokenValidityKeyValidAsync(
            [NotNull] TUser user,
            string tokenValidityKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Tokens, cancellationToken);
                return user.Tokens.Any(t => t.LoginProvider == TokenValidityKeyProvider &&
                                            t.Name == tokenValidityKey &&
                                            t.ExpireDate > DateTime.UtcNow);
            });
        }

        public virtual bool IsTokenValidityKeyValid(
            [NotNull] TUser user,
            string tokenValidityKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                UserRepository.EnsureCollectionLoaded(user, u => u.Tokens, cancellationToken);
                var isValidityKeyValid = user.Tokens.Any(t => t.LoginProvider == TokenValidityKeyProvider &&
                                                              t.Name == tokenValidityKey &&
                                                              t.ExpireDate > DateTime.UtcNow);

                user.Tokens.RemoveAll(t =>
                    t.LoginProvider == TokenValidityKeyProvider && t.ExpireDate <= DateTime.UtcNow);

                return isValidityKeyValid;
            });
        }

        public virtual async Task RemoveTokenValidityKeyAsync(
            [NotNull] TUser user,
            string tokenValidityKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                await UserRepository.EnsureCollectionLoadedAsync(user, u => u.Tokens, cancellationToken);
                user.Tokens.RemoveAll(t => t.LoginProvider == TokenValidityKeyProvider && t.Name == tokenValidityKey);
            });
        }

        public virtual void RemoveTokenValidityKey(
            [NotNull] TUser user,
            string tokenValidityKey,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                cancellationToken.ThrowIfCancellationRequested();
                Check.NotNull(user, nameof(user));
                UserRepository.EnsureCollectionLoaded(user, u => u.Tokens, cancellationToken);
                user.Tokens.Remove(user.Tokens.FirstOrDefault(t =>
                    t.LoginProvider == TokenValidityKeyProvider && t.Name == tokenValidityKey)
                );
            });
        }

        protected virtual string NormalizeKey(string key)
        {
            return key.ToUpperInvariant();
        }
    }
}
