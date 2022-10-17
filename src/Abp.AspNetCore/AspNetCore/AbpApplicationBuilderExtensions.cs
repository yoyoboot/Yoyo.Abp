using System;
using System.Linq;
using Abp.AspNetCore.EmbeddedResources;
using Abp.AspNetCore.Localization;
using Abp.Dependency;
using Abp.Localization;
using Castle.LoggingFacility.MsLogging;
using JetBrains.Annotations;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Localization;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Globalization;
using Abp.AspNetCore.ExceptionHandling;
using Abp.AspNetCore.Security;
using Abp.AspNetCore.Uow;
using Microsoft.Extensions.Hosting;

namespace Abp.AspNetCore
{
    public static class AbpApplicationBuilderExtensions
    {
        private const string AuthorizationExceptionHandlingMiddlewareMarker = "_AbpAuthorizationExceptionHandlingMiddleware_Added";

        public static void UseAbp(this IApplicationBuilder app)
        {
            app.UseAbp(null);
        }

        public static void UseAbp([NotNull] this IApplicationBuilder app, Action<AbpApplicationBuilderOptions> optionsAction)
        {
            Check.NotNull(app, nameof(app));

            var options = new AbpApplicationBuilderOptions();
            optionsAction?.Invoke(options);

            if (options.UseCastleLoggerFactory)
            {
                app.UseCastleLoggerFactory();
            }

            InitializeAbp(app);

            if (options.UseAbpRequestLocalization)
            {
                //TODO: This should be added later than authorization middleware!
                app.UseAbpRequestLocalization();
            }

            if (options.UseSecurityHeaders)
            {
                app.UseAbpSecurityHeaders();
            }
        }

        public static void UseEmbeddedFiles(this IApplicationBuilder app)
        {
            app.UseStaticFiles(
                new StaticFileOptions
                {
                    FileProvider = new EmbeddedResourceFileProvider(
                        app.ApplicationServices.GetRequiredService<IIocResolver>()
                    )
                }
            );
        }

        private static void InitializeAbp(IApplicationBuilder app)
        {
            var abpBootstrapper = app.ApplicationServices.GetRequiredService<AbpBootstrapper>();
            abpBootstrapper.Initialize();

            var applicationLifetime = app.ApplicationServices.GetService<IHostApplicationLifetime>();
            applicationLifetime.ApplicationStopping.Register(() => abpBootstrapper.Dispose());
        }

        public static void UseCastleLoggerFactory(this IApplicationBuilder app)
        {
            var castleLoggerFactory = app.ApplicationServices.GetService<Castle.Core.Logging.ILoggerFactory>();
            if (castleLoggerFactory == null)
            {
                return;
            }

            app.ApplicationServices
                .GetRequiredService<ILoggerFactory>()
                .AddCastleLogger(castleLoggerFactory);
        }

        public static void UseAbpRequestLocalization(this IApplicationBuilder app, Action<RequestLocalizationOptions> optionsAction = null)
        {
            var iocResolver = app.ApplicationServices.GetRequiredService<IIocResolver>();
            using (var languageManager = iocResolver.ResolveAsDisposable<ILanguageManager>())
            {
                var supportedCultures = languageManager.Object
                    .GetActiveLanguages()
                    .Select(l => CultureInfo.GetCultureInfo(l.Name))
                    .ToArray();

                if (iocResolver.IsRegistered<ILogger<RequestLocalizationOptions>>())
                {
                    using (var logger = iocResolver.ResolveAsDisposable<ILogger<RequestLocalizationOptions>>())
                    {
                        logger.Object.LogInformation($"Supported Request Localization Cultures: {string.Join(",", supportedCultures.Select(c => c))}");
                    }
                }

                var options = new RequestLocalizationOptions
                {
                    SupportedCultures = supportedCultures,
                    SupportedUICultures = supportedCultures
                };

                var userProvider = new AbpUserRequestCultureProvider();

                //0: QueryStringRequestCultureProvider
                options.RequestCultureProviders.Insert(1, userProvider);
                options.RequestCultureProviders.Insert(2, new AbpLocalizationHeaderRequestCultureProvider());
                //3: CookieRequestCultureProvider
                //4: AcceptLanguageHeaderRequestCultureProvider
                options.RequestCultureProviders.Insert(5, new AbpDefaultRequestCultureProvider());

                optionsAction?.Invoke(options);

                userProvider.CookieProvider = options.RequestCultureProviders.OfType<CookieRequestCultureProvider>().FirstOrDefault();
                userProvider.HeaderProvider = options.RequestCultureProviders.OfType<AbpLocalizationHeaderRequestCultureProvider>().FirstOrDefault();

                app.UseRequestLocalization(options);
            }
        }

        public static void UseAbpSecurityHeaders(this IApplicationBuilder app)
        {
            app.UseMiddleware<AbpSecurityHeadersMiddleware>();
        }

        public static IApplicationBuilder UseUnitOfWork(this IApplicationBuilder app)
        {
            return app
                .UseMiddleware<AbpUnitOfWorkMiddleware>();
        }

        public static IApplicationBuilder UseAbpAuthorizationExceptionHandling(this IApplicationBuilder app)
        {
            if (app.Properties.ContainsKey(AuthorizationExceptionHandlingMiddlewareMarker))
            {
                return app;
            }

            app.Properties[AuthorizationExceptionHandlingMiddlewareMarker] = true;
            return app.UseMiddleware<AbpAuthorizationExceptionHandlingMiddleware>();
        }
    }
}
