using System.Collections.Generic;
using System.Collections.Immutable;
using System.Data.Entity;
using System.Data.Entity.Core.Objects;
using System.Data.Entity.Infrastructure;
using System.Linq;
using System.Threading.Tasks;
using Abp.Dependency;
using Abp.Domain.Uow;
using Abp.EntityFramework.Utils;
using Abp.Extensions;
using Abp.MultiTenancy;
using Abp.Timing;
using Castle.Core.Internal;

namespace Abp.EntityFramework.Uow
{
    /// <summary>
    /// Implements Unit of work for Entity Framework.
    /// </summary>
    public class EfUnitOfWork : UnitOfWorkBase, ITransientDependency
    {
        protected IDictionary<string, DbContext> ActiveDbContexts { get; }
        protected IIocResolver IocResolver { get; }

        private readonly IDbContextResolver _dbContextResolver;
        private readonly IDbContextTypeMatcher _dbContextTypeMatcher;
        private readonly IEfTransactionStrategy _transactionStrategy;

        /// <summary>
        /// Creates a new <see cref="EfUnitOfWork"/>.
        /// </summary>
        public EfUnitOfWork(
            IIocResolver iocResolver,
            IConnectionStringResolver connectionStringResolver,
            IDbContextResolver dbContextResolver,
            IEfUnitOfWorkFilterExecuter filterExecuter,
            IUnitOfWorkDefaultOptions defaultOptions,
            IDbContextTypeMatcher dbContextTypeMatcher,
            IEfTransactionStrategy transactionStrategy)
            : base(
                connectionStringResolver,
                defaultOptions,
                filterExecuter)
        {
            IocResolver = iocResolver;
            _dbContextResolver = dbContextResolver;
            _dbContextTypeMatcher = dbContextTypeMatcher;
            _transactionStrategy = transactionStrategy;

            ActiveDbContexts = new Dictionary<string, DbContext>(System.StringComparer.OrdinalIgnoreCase);
        }

        protected override void BeginUow()
        {
            if (Options.IsTransactional == true)
            {
                _transactionStrategy.InitOptions(Options);
            }
        }

        public override void SaveChanges()
        {
            foreach (var dbContext in GetAllActiveDbContexts())
            {
                SaveChangesInDbContext(dbContext);
            }
        }

        public override async Task SaveChangesAsync()
        {
            foreach (var dbContext in GetAllActiveDbContexts())
            {
                await SaveChangesInDbContextAsync(dbContext);
            }
        }

        public IReadOnlyList<DbContext> GetAllActiveDbContexts()
        {
            return ActiveDbContexts.Values.ToImmutableList();
        }

        protected override void CompleteUow()
        {
            SaveChanges();

            if (Options.IsTransactional == true)
            {
                _transactionStrategy.Commit();
            }
        }

        protected override async Task CompleteUowAsync()
        {
            await SaveChangesAsync();

            if (Options.IsTransactional == true)
            {
                _transactionStrategy.Commit();
            }
        }

        public virtual TDbContext GetOrCreateDbContext<TDbContext>(MultiTenancySides? multiTenancySide = null,
            string name = null)
            where TDbContext : DbContext
        {
            var concreteDbContextType = _dbContextTypeMatcher.GetConcreteType(typeof(TDbContext));

            var connectionStringResolveArgs = new ConnectionStringResolveArgs(multiTenancySide)
            {
                ["DbContextType"] = typeof(TDbContext),
                ["DbContextConcreteType"] = concreteDbContextType
            };

            var connectionString = ResolveConnectionString(connectionStringResolveArgs);

            var dbContextKey = concreteDbContextType.FullName + "#" + connectionString;
            if (name != null)
            {
                dbContextKey += "#" + name;
            }

            if (ActiveDbContexts.TryGetValue(dbContextKey, out var dbContext))
            {
                return (TDbContext) dbContext;
            }

            if (Options.IsTransactional == true)
            {
                dbContext = _transactionStrategy.CreateDbContext<TDbContext>(connectionString, _dbContextResolver);
            }
            else
            {
                dbContext = _dbContextResolver.Resolve<TDbContext>(connectionString);
            }

            if (dbContext is IShouldInitializeDcontext abpDbContext)
            {
                abpDbContext.Initialize(new AbpEfDbContextInitializationContext(this));
            }

            FilterExecuter.As<IEfUnitOfWorkFilterExecuter>().ApplyCurrentFilters(this, dbContext);

            ActiveDbContexts[dbContextKey] = dbContext;

            return (TDbContext) dbContext;
        }

        public virtual async Task<TDbContext> GetOrCreateDbContextAsync<TDbContext>(
            MultiTenancySides? multiTenancySide = null, string name = null)
            where TDbContext : DbContext
        {
            var concreteDbContextType = _dbContextTypeMatcher.GetConcreteType(typeof(TDbContext));

            var connectionStringResolveArgs = new ConnectionStringResolveArgs(multiTenancySide)
            {
                ["DbContextType"] = typeof(TDbContext),
                ["DbContextConcreteType"] = concreteDbContextType
            };

            var connectionString = await ResolveConnectionStringAsync(connectionStringResolveArgs);

            var dbContextKey = concreteDbContextType.FullName + "#" + connectionString;
            if (name != null)
            {
                dbContextKey += "#" + name;
            }

            if (ActiveDbContexts.TryGetValue(dbContextKey, out var dbContext))
            {
                return (TDbContext) dbContext;
            }

            if (Options.IsTransactional == true)
            {
                dbContext = await _transactionStrategy
                    .CreateDbContextAsync<TDbContext>(connectionString, _dbContextResolver);
            }
            else
            {
                dbContext = _dbContextResolver.Resolve<TDbContext>(connectionString);
            }

            if (dbContext is IShouldInitializeDcontext abpDbContext)
            {
                abpDbContext.Initialize(new AbpEfDbContextInitializationContext(this));
            }

            FilterExecuter.As<IEfUnitOfWorkFilterExecuter>().ApplyCurrentFilters(this, dbContext);

            ActiveDbContexts[dbContextKey] = dbContext;

            return (TDbContext) dbContext;
        }

        protected override void DisposeUow()
        {
            if (Options.IsTransactional == true)
            {
                _transactionStrategy.Dispose(IocResolver);
            }
            else
            {
                foreach (var activeDbContext in GetAllActiveDbContexts())
                {
                    Release(activeDbContext);
                }
            }

            ActiveDbContexts.Clear();
        }

        protected virtual void SaveChangesInDbContext(DbContext dbContext)
        {
            dbContext.SaveChanges();
        }

        protected virtual Task SaveChangesInDbContextAsync(DbContext dbContext)
        {
            return dbContext.SaveChangesAsync();
        }

        protected virtual void Release(DbContext dbContext)
        {
            dbContext.Dispose();
            IocResolver.Release(dbContext);
        }
    }
}
