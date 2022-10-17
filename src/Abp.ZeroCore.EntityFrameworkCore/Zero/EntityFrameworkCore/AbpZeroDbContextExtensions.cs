using Abp.Application.Features;
using Abp.Authorization.Roles;
using Abp.Authorization.Users;
using Abp.Domain.Entities;
using Abp.DynamicEntityProperties;
using Abp.EntityHistory;
using Abp.MultiTenancy;

using Microsoft.EntityFrameworkCore;
using System.Linq;
using Microsoft.EntityFrameworkCore.ValueGeneration;
using Microsoft.EntityFrameworkCore.Metadata;
using System.Collections;
using System.Collections.Generic;
using Abp.BackgroundJobs;
using Abp.Notifications;
using Abp.Authorization;
using Abp.Configuration;
using Abp.Auditing;
using Abp.Localization;
using Abp.Organizations;
using Abp.Webhooks;
using Abp.Domain.Entities.Auditing;
using Abp.Application.Editions;
using Abp.EntityFrameworkCore;

namespace Abp.Zero.EntityFrameworkCore
{
    public static class AbpZeroDbContextExtensions
    {

        /// <summary>
        /// 配置zero模块,使用 <see cref="AbpStringPrimaryKeyValueGenerator"/> 生成字符串类型主键
        /// </summary>
        /// <typeparam name="TTenant">租户类型</typeparam>
        /// <typeparam name="TRole">角色类型</typeparam>
        /// <typeparam name="TUser">用户类型</typeparam>
        /// <param name="modelBuilder"></param>
        /// <param name="maxLength"></param>
        /// <returns></returns>
        public static ModelBuilder ConfigurationZeroModule<TTenant, TRole, TUser>(this ModelBuilder modelBuilder, int maxLength = 32)
          where TTenant : AbpTenant<TUser>
          where TRole : AbpRole<TUser>
          where TUser : AbpUser<TUser>
        {
            return modelBuilder.ConfigurationZeroModule<TTenant, TRole, TUser, AbpStringPrimaryKeyValueGenerator>(maxLength);
        }

        /// <summary>
        /// 配置zero模块
        /// </summary>
        /// <typeparam name="TTenant">租户类型</typeparam>
        /// <typeparam name="TRole">角色类型</typeparam>
        /// <typeparam name="TUser">用户类型</typeparam>
        /// <typeparam name="TStringPrimaryKeyValueGenerator">字符串主键值生成器类型</typeparam>
        /// <param name="modelBuilder"></param>
        /// <param name="maxLength"></param>
        /// <returns></returns>
        public static ModelBuilder ConfigurationZeroModule<TTenant, TRole, TUser, TStringPrimaryKeyValueGenerator>(this ModelBuilder modelBuilder, int maxLength = 32)
            where TTenant : AbpTenant<TUser>
            where TRole : AbpRole<TUser>
            where TUser : AbpUser<TUser>
            where TStringPrimaryKeyValueGenerator : ValueGenerator<string>
        {

            modelBuilder.ConfigurationZeroModuleEntity(maxLength);

            modelBuilder.ConfigurationZeroModuleCommon<TTenant, TRole, TUser, TStringPrimaryKeyValueGenerator>(maxLength);

            return modelBuilder;
        }


        /// <summary>
        /// 配置Zero模块实体
        /// </summary>
        /// <param name="modelBuilder"></param>
        /// <param name="maxLength"></param>
        /// <returns></returns>
        public static ModelBuilder ConfigurationZeroModuleEntity(this ModelBuilder modelBuilder, int maxLength = 32)
        {
            // 实体关系
            modelBuilder.Entity<EditionFeatureSetting>((b) =>
            {
                b.HasOne(o => o.Edition)
                    .WithMany()
                    .HasForeignKey(o => o.EditionId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .IsRequired(false);
            });

            modelBuilder.Entity<DynamicEntityProperty>((b) =>
            {
                b.HasOne(o => o.DynamicProperty)
                    .WithMany()
                    .HasForeignKey(o => o.DynamicPropertyId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .IsRequired(false);
            });


            modelBuilder.Entity<AuditLog>((eb) =>
            {
                eb.Property(o => o.ImpersonatorTenantId).HasMaxLength(maxLength);
                eb.Property(o => o.ImpersonatorUserId).HasMaxLength(maxLength);
            });
            //modelBuilder.Entity<AuditLog2>((eb) =>
            //{
            //    eb.Property(o => o.ImpersonatorTenantId).HasMaxLength(32);
            //    eb.Property(o => o.ImpersonatorUserId).HasMaxLength(32);
            //});
            //modelBuilder.Entity<Edition>((eb) =>
            //{
            //    eb.Property(o => o.ExpiringEditionId).HasMaxLength(32);
            //});
            modelBuilder.Entity<EntityChangeSet>((eb) =>
            {
                eb.Property(o => o.ImpersonatorTenantId).HasMaxLength(maxLength);
                eb.Property(o => o.ImpersonatorUserId).HasMaxLength(maxLength);
                eb.Property(o => o.UserId).HasMaxLength(32);
            });
            modelBuilder.Entity<NotificationSubscriptionInfo>((eb) =>
            {
                eb.Property(o => o.UserId).HasMaxLength(maxLength);
            });

            modelBuilder.Entity<OrganizationUnitRole>((eb) =>
            {
                eb.Property(o => o.OrganizationUnitId).HasMaxLength(maxLength);
                eb.Property(o => o.RoleId).HasMaxLength(maxLength);
            });

            modelBuilder.Entity<UserAccount>((eb) =>
            {
                eb.Property(o => o.TenantId).HasMaxLength(maxLength);
                eb.Property(o => o.UserId).HasMaxLength(maxLength);
                eb.Property(o => o.UserLinkId).HasMaxLength(maxLength);
            });

            modelBuilder.Entity<UserLoginAttempt>((eb) =>
            {
                eb.Property(o => o.UserId).HasMaxLength(maxLength);
            });

            modelBuilder.Entity<UserNotificationInfo>((eb) =>
            {
                eb.Property(o => o.UserId).HasMaxLength(maxLength);
            });

            modelBuilder.Entity<UserOrganizationUnit>((eb) =>
            {
                eb.Property(o => o.UserId).HasMaxLength(maxLength);
                eb.Property(o => o.OrganizationUnitId).HasMaxLength(maxLength);
            });

            //modelBuilder.Entity<WebhookSubscription>((eb) =>
            //{
            //    eb.Property(o => o.TenantId).HasMaxLength(maxLength);
            //});


            return modelBuilder;
        }


        /// <summary>
        /// 配置Zero模块通用
        /// </summary>
        /// <typeparam name="TTenant"></typeparam>
        /// <typeparam name="TRole"></typeparam>
        /// <typeparam name="TUser"></typeparam>
        /// <typeparam name="TStringPrimaryKeyValueGenerator"></typeparam>
        /// <param name="modelBuilder"></param>
        /// <param name="maxLength"></param>
        /// <returns></returns>
        public static ModelBuilder ConfigurationZeroModuleCommon<TTenant, TRole, TUser, TStringPrimaryKeyValueGenerator>(this ModelBuilder modelBuilder, int maxLength = 32)
            where TTenant : AbpTenant<TUser>
            where TRole : AbpRole<TUser>
            where TUser : AbpUser<TUser>
            where TStringPrimaryKeyValueGenerator : ValueGenerator<string>
        {
            modelBuilder.ConfigurationAbpDbContext<TStringPrimaryKeyValueGenerator>(maxLength,
                (entityType, fk) =>
            {
                return entityType.ClrType == typeof(TRole) || entityType.ClrType == typeof(TUser);
            }, (entityType, fk) =>
            {
                return fk.PrincipalEntityType.ClrType == typeof(TUser) && fk.DependentToPrincipal != null;
            });
            return modelBuilder;
        }

        #region 兼容long类型主键

        ///// <summary>
        ///// Zero模块主键自增并设置映射为long类型
        ///// </summary>
        ///// <typeparam name="TTenant"></typeparam>
        ///// <typeparam name="TRole"></typeparam>
        ///// <typeparam name="TUser"></typeparam>
        ///// <param name="modelBuilder"></param>
        ///// <returns></returns>
        //public static ModelBuilder ConfigurationZeroModuleLong<TTenant, TRole, TUser>(this ModelBuilder modelBuilder)
        //  where TTenant : AbpTenant<TUser>
        //  where TRole : AbpRole<TUser>
        //  where TUser : AbpUser<TUser>
        //{

        //    modelBuilder.ConfigurationZeroModule<TTenant, TRole, TUser>(false);


        //    modelBuilder.SetStringIdConversionLong<TTenant>();
        //    modelBuilder.SetStringIdConversionLong<TUser>();
        //    modelBuilder.SetStringIdConversionLong<TRole>();
        //    modelBuilder.SetStringIdConversionLong<FeatureSetting>();
        //    modelBuilder.SetStringIdConversionLong<TenantFeatureSetting>(false);
        //    modelBuilder.SetStringIdConversionLong<EditionFeatureSetting>(false);
        //    modelBuilder.SetStringIdConversionLong<BackgroundJobInfo>();
        //    modelBuilder.SetStringIdConversionLong<UserAccount>();
        //    modelBuilder.SetStringIdConversionLong<NotificationInfo>();

        //    modelBuilder.SetStringIdConversionLong<UserLogin>();
        //    modelBuilder.SetStringIdConversionLong<UserLoginAttempt>();
        //    modelBuilder.SetStringIdConversionLong<UserRole>();
        //    modelBuilder.SetStringIdConversionLong<UserClaim>();
        //    modelBuilder.SetStringIdConversionLong<UserToken>();
        //    modelBuilder.SetStringIdConversionLong<RoleClaim>();
        //    modelBuilder.SetStringIdConversionLong<PermissionSetting>();
        //    modelBuilder.SetStringIdConversionLong<RolePermissionSetting>(false);
        //    modelBuilder.SetStringIdConversionLong<UserPermissionSetting>(false);
        //    modelBuilder.SetStringIdConversionLong<Setting>();
        //    modelBuilder.SetStringIdConversionLong<AuditLog>();
        //    modelBuilder.SetStringIdConversionLong<ApplicationLanguage>();
        //    modelBuilder.SetStringIdConversionLong<ApplicationLanguageText>();
        //    modelBuilder.SetStringIdConversionLong<OrganizationUnit>();
        //    modelBuilder.SetStringIdConversionLong<UserOrganizationUnit>();
        //    modelBuilder.SetStringIdConversionLong<OrganizationUnitRole>();

        //    modelBuilder.SetStringIdConversionLong<TenantNotificationInfo>();
        //    modelBuilder.SetStringIdConversionLong<UserNotificationInfo>();
        //    modelBuilder.SetStringIdConversionLong<NotificationSubscriptionInfo>();

        //    modelBuilder.SetStringIdConversionLong<EntityChange>();
        //    modelBuilder.SetStringIdConversionLong<EntityChangeSet>();
        //    modelBuilder.SetStringIdConversionLong<EntityPropertyChange>();

        //    modelBuilder.SetStringIdConversionLong<WebhookEvent>();
        //    modelBuilder.SetStringIdConversionLong<WebhookSubscriptionInfo>();
        //    modelBuilder.SetStringIdConversionLong<WebhookSendAttempt>();

        //    modelBuilder.SetStringIdConversionLong<DynamicProperty>();
        //    modelBuilder.SetStringIdConversionLong<DynamicPropertyValue>();
        //    modelBuilder.SetStringIdConversionLong<DynamicEntityProperty>();
        //    modelBuilder.SetStringIdConversionLong<DynamicEntityPropertyValue>();



        //    return modelBuilder;
        //}

        ///// <summary>
        ///// 设置
        ///// </summary>
        ///// <typeparam name="TEntity"></typeparam>
        ///// <param name="modelBuilder"></param>
        ///// <param name="hasKey"></param>
        //public static void SetStringIdConversionLong<TEntity>(this ModelBuilder modelBuilder, bool hasKey = true)
        //   where TEntity : class
        //{

        //    var entityType = typeof(TEntity);

        //    modelBuilder.Entity<TEntity>((eb) =>
        //    {
        //        if (typeof(IEntity<string>).IsAssignableFrom(entityType))
        //        {
        //            eb.Property(nameof(IEntity<string>.Id))
        //                .HasConversion<long>()
        //                .ValueGeneratedOnAdd()
        //           ;



        //            if (hasKey)
        //            {
        //                eb.HasKey(nameof(IEntity<string>.Id));
        //            }
        //        }


        //        #region 多租户

        //        if (typeof(IMayHaveTenant).IsAssignableFrom(entityType))
        //        {
        //            eb.Property(nameof(IMayHaveTenant.TenantId))
        //                .HasConversion<long?>()
        //                .IsRequired(false)
        //                .HasDefaultValue(null)
        //                ;
        //        }

        //        if (typeof(IMustHaveTenant).IsAssignableFrom(entityType))
        //        {
        //            eb.Property(nameof(IMustHaveTenant.TenantId))
        //                .HasConversion<long>()
        //                .IsRequired(true)
        //                ;
        //        }

        //        #endregion

        //        #region 审计

        //        if (typeof(ICreationAudited).IsAssignableFrom(entityType))
        //        {
        //            eb.Property(nameof(ICreationAudited.CreatorUserId))
        //                .HasConversion<long?>()
        //                .IsRequired(false)
        //                .HasDefaultValue(null)
        //                ;
        //        }


        //        if (typeof(IDeletionAudited).IsAssignableFrom(entityType))
        //        {
        //            eb.Property(nameof(IDeletionAudited.DeleterUserId))
        //                .HasConversion<long?>()
        //                .IsRequired(false)
        //                .HasDefaultValue(null)
        //                ;
        //        }

        //        if (typeof(IModificationAudited).IsAssignableFrom(entityType))
        //        {
        //            eb.Property(nameof(IModificationAudited.LastModifierUserId))
        //                .HasConversion<long?>()
        //                .IsRequired(false)
        //                .HasDefaultValue(null)
        //                ;
        //        }

        //        #endregion
        //    });
        //} 
        #endregion
    }
}
