using System;
using System.Threading.Tasks;
using Abp.AspNetCore.TestBase;
using Abp.Domain.Uow;
using Abp.Modules;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Shouldly;
using Xunit;

namespace Abp.AspNetCore.Tests.Uow
{
    public class UnitOfWorkMiddleware_Tests : AbpAspNetCoreIntegratedTestBase<UnitOfWorkMiddleware_Tests.Startup>
    {
        // NET6: Wait for .NET 6 Preview 7 for fix.
        [Fact]
        public async Task Current_UnitOfWork_Should_Be_Available_After_UnitOfWork_Middleware()
        {
            var response = await Client.GetAsync("/");
            var str = await response.Content.ReadAsStringAsync();
            str.ShouldBe("not-null");
        }

        public class Startup
        {
            public IServiceProvider ConfigureServices(IServiceCollection services)
            {
                return services.AddAbp<StartupModule>(options =>
                {
                    options.SetupTest();
                });
            }

            public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILoggerFactory loggerFactory)
            {
                app.UseAbp();

                app.UseUnitOfWork();

                app.Run(async (context) =>
                {
                    await context.Response.WriteAsync(
                        context.RequestServices.GetRequiredService<IUnitOfWorkManager>().Current == null
                            ? "null"
                            : "not-null"
                    );
                });
            }
        }

        public class StartupModule : AbpModule
        {
            
        }
    }
}
