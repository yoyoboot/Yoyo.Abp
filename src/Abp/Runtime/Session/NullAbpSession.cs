using Abp.Configuration.Startup;
using Abp.MultiTenancy;
using Abp.Runtime.Remoting;

namespace Abp.Runtime.Session
{
    /// <summary>
    /// Implements null object pattern for <see cref="IAbpSession"/>.
    /// </summary>
    public class NullAbpSession : AbpSessionBase
    {
        /// <summary>
        /// Singleton instance.
        /// </summary>
        public static NullAbpSession Instance { get; } = new NullAbpSession();

        /// <inheritdoc/>
        public override string UserId => null;

        /// <inheritdoc/>
        public override string TenantId => null;

        public override MultiTenancySides MultiTenancySide => MultiTenancySides.Tenant;

        public override string ImpersonatorUserId => null;

        public override string ImpersonatorTenantId => null;

        private NullAbpSession() 
            : base(
                  new MultiTenancyConfig(), 
                  new DataContextAmbientScopeProvider<SessionOverride>(new AsyncLocalAmbientDataContext())
            )
        {

        }
    }
}
