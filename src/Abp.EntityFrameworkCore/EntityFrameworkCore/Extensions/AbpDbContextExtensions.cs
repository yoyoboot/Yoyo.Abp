using Abp.Domain.Entities;
using Abp.DynamicEntityProperties;
using Abp.EntityHistory;

using Microsoft.EntityFrameworkCore;
using System.Linq;
using Microsoft.EntityFrameworkCore.ValueGeneration;
using System.Collections;

using Abp.Domain.Entities.Auditing;
using System;
using Microsoft.EntityFrameworkCore.Metadata;

namespace Abp.EntityFrameworkCore
{
    public static class AbpDbContextExtensions
    {
        /// <summary>
        /// 配置AbpDbContext
        /// </summary>
        /// <param name="modelBuilder"></param>
        /// <param name="maxLength">主键最大长度</param>
        /// <param name="referencingForeignKeysFilter">引用型外键过滤器</param>
        /// <param name="auditingForeignKeysFilter">审计外键过滤器</param>
        public static void ConfigurationAbpDbContext(this ModelBuilder modelBuilder, int maxLength = 32, Func<IMutableEntityType, IMutableForeignKey, bool> referencingForeignKeysFilter = null, Func<IMutableEntityType, IMutableForeignKey, bool> auditingForeignKeysFilter = null)
        {
            modelBuilder.ConfigurationAbpDbContext<AbpStringPrimaryKeyValueGenerator>(maxLength, referencingForeignKeysFilter, auditingForeignKeysFilter);
        }

        /// <summary>
        /// 配置AbpDbContext
        /// </summary>
        /// <typeparam name="TStringPrimaryKeyValueGenerator"></typeparam>
        /// <param name="modelBuilder"></param>
        /// <param name="maxLength">主键最大长度</param>
        /// <param name="referencingForeignKeysFilter">引用型外键过滤器</param>
        /// <param name="auditingForeignKeysFilter">审计外键过滤器</param>
        public static void ConfigurationAbpDbContext<TStringPrimaryKeyValueGenerator>(this ModelBuilder modelBuilder, int maxLength = 32, Func<IMutableEntityType, IMutableForeignKey, bool> referencingForeignKeysFilter = null, Func<IMutableEntityType, IMutableForeignKey, bool> auditingForeignKeysFilter = null)
            where TStringPrimaryKeyValueGenerator : ValueGenerator<string>
        {
            modelBuilder.EntitySetup((entity) =>
            {
                modelBuilder.ConfigurationPrimaryKey<TStringPrimaryKeyValueGenerator>(entity, maxLength);
                modelBuilder.ConfigurationMultiTenancy(entity, maxLength);
                modelBuilder.ConfigurationAuditing(entity, maxLength);
                modelBuilder.ConfigurationForeignKeys(entity, referencingForeignKeysFilter, auditingForeignKeysFilter);
            });
        }



        #region 实体主键、审计、外键 扩展方法

        /// <summary>
        /// 配置主键
        /// </summary>
        /// <param name="modelBuilder"></param>
        /// <param name="entityType"></param>
        /// <param name="maxLength"></param>
        public static void ConfigurationPrimaryKey(this ModelBuilder modelBuilder, IMutableEntityType entityType, int maxLength = 32)
        {
            ConfigurationPrimaryKey<AbpStringPrimaryKeyValueGenerator>(modelBuilder, entityType, maxLength);
        }

        /// <summary>
        /// 配置主键
        /// </summary>
        /// <typeparam name="TStringPrimaryKeyValueGenerator"></typeparam>
        /// <param name="modelBuilder"></param>
        /// <param name="entityType"></param>
        /// <param name="maxLength"></param>
        public static void ConfigurationPrimaryKey<TStringPrimaryKeyValueGenerator>(this ModelBuilder modelBuilder, IMutableEntityType entityType, int maxLength = 32)
             where TStringPrimaryKeyValueGenerator : ValueGenerator<string>
        {
            // 主键字段为string
            if (typeof(IEntity<string>).IsAssignableFrom(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(IEntity<string>.Id))
                    .HasMaxLength(maxLength)
                    .HasValueGenerator<TStringPrimaryKeyValueGenerator>();
            }
        }

        /// <summary>
        /// 配置多租户
        /// </summary>
        /// <param name="modelBuilder"></param>
        /// <param name="entityType"></param>
        /// <param name="maxLength"></param>
        public static void ConfigurationMultiTenancy(this ModelBuilder modelBuilder, IMutableEntityType entityType, int maxLength = 32)
        {
            // 主键字段为string
            if (typeof(IMayHaveTenant).IsAssignableFrom(entityType.ClrType)
                || typeof(IMustHaveTenant).IsAssignableFrom(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(IMayHaveTenant.TenantId))
                    .HasMaxLength(maxLength);
            }
        }


        /// <summary>
        /// 配置审计键
        /// </summary>
        /// <param name="modelBuilder"></param>
        /// <param name="entityType"></param>
        /// <param name="maxLength"></param>
        public static void ConfigurationAuditing(this ModelBuilder modelBuilder, IMutableEntityType entityType, int maxLength = 32)
        {
            // 增删改审计长度限制
            if (typeof(ICreationAudited).IsAssignableFrom(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(ICreationAudited.CreatorUserId))
                    .HasMaxLength(maxLength);
            }
            if (typeof(IDeletionAudited).IsAssignableFrom(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(IDeletionAudited.DeleterUserId))
                    .HasMaxLength(maxLength);
            }
            if (typeof(IModificationAudited).IsAssignableFrom(entityType.ClrType))
            {
                modelBuilder.Entity(entityType.ClrType)
                    .Property(nameof(IModificationAudited.LastModifierUserId))
                    .HasMaxLength(maxLength);
            }
        }


        /// <summary>
        /// 配置外键
        /// </summary>
        /// <param name="modelBuilder"></param>
        /// <param name="entityType"></param>
        /// <param name="referencingForeignKeysFilter">引用型外键过滤器</param>
        /// <param name="auditingForeignKeysFilter">审计外键过滤器</param>
        public static void ConfigurationForeignKeys(this ModelBuilder modelBuilder, IMutableEntityType entityType, Func<IMutableEntityType, IMutableForeignKey, bool> referencingForeignKeysFilter = null, Func<IMutableEntityType, IMutableForeignKey, bool> auditingForeignKeysFilter = null)
        {
            if (referencingForeignKeysFilter == null)
            {
                referencingForeignKeysFilter = (e, foreignKey) => false;
            }
            if (auditingForeignKeysFilter == null)
            {
                auditingForeignKeysFilter = (e, foreignKey) => foreignKey.DependentToPrincipal != null;
            }


            // 引用型外键约束，设置为关联删除
            var referencingForeignKeys = entityType.GetReferencingForeignKeys().ToList();
            foreach (var item in referencingForeignKeys)
            {
                if (referencingForeignKeysFilter(entityType, item)
                    || entityType.ClrType == typeof(DynamicProperty)
                    || entityType.ClrType == typeof(DynamicEntityProperty)
                    || entityType.ClrType == typeof(EntityChangeSet)
                    || entityType.ClrType == typeof(EntityChange)
                    )
                {
                    if (item.PrincipalToDependent != null
                        && item.PrincipalToDependent.ClrType.GetInterface(nameof(IEnumerable)) != null)
                    {
                        item.DeleteBehavior = DeleteBehavior.Cascade;
                    }
                }
            }

            // 其它外键
            var foreignKeys = entityType.GetForeignKeys().ToList();
            foreach (var item in foreignKeys)
            {
                // 审计用户信息，设置为空         
                if (auditingForeignKeysFilter(entityType, item))
                {
                    if (item.DependentToPrincipal.Name == "CreatorUser"
                        || item.DependentToPrincipal.Name == "DeleterUser"
                        || item.DependentToPrincipal.Name == "LastModifierUser"
                    )
                    {
                        item.DeleteBehavior = DeleteBehavior.ClientSetNull;
                    }
                }
            }
        }


        #endregion



        #region 实体配置扩展方法

        /// <summary>
        /// 实体配置
        /// </summary>
        /// <param name="modelBuilder"></param>
        /// <param name="setupAction"></param>
        /// <returns></returns>
        public static ModelBuilder EntitySetup(this ModelBuilder modelBuilder, Action<IMutableEntityType> setupAction)
        {
            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                setupAction?.Invoke(entityType);
            }

            return modelBuilder;
        }

        #endregion
    }
}
