using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using Abp.Configuration.Startup;
using Microsoft.Extensions.Caching.Memory;

namespace Abp.Runtime.Caching.Configuration
{
    internal class CachingConfiguration : ICachingConfiguration
    {
        public IAbpStartupConfiguration AbpConfiguration { get; private set; }

        public IReadOnlyList<ICacheConfigurator> Configurators
        {
            get { return _configurators.ToImmutableList(); }
        }

        public MemoryCacheOptions MemoryCacheOptions { get; set; }
        
        private readonly List<ICacheConfigurator> _configurators;

        public CachingConfiguration(IAbpStartupConfiguration abpConfiguration)
        {
            AbpConfiguration = abpConfiguration;

            _configurators = new List<ICacheConfigurator>();
        }

        public void ConfigureAll(Action<ICacheOptions> initAction)
        {
            _configurators.Add(new CacheConfigurator(initAction));
        }

        public void Configure(string cacheName, Action<ICacheOptions> initAction)
        {
            _configurators.Add(new CacheConfigurator(cacheName, initAction));
        }
    }
}
