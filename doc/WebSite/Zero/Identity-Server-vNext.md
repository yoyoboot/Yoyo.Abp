### Introduction

[Identity Server](http://identityserver.io/) is an open source **OpenID
Connect** and **OAuth 2.0** framework. It can be used to make your
application an **authentication / single sign on server**. It can also
issue **access tokens** for 3rd party clients. This document describes
how you can integrate IdentityServer4 (version **2.0+**) to your
project.

#### Startup Project

**This document applies to the 4.x+ version of Identity Server 4.  If you are using the 3.x version of Identity Server 4, please refer to [Identity Server 4](../Zero/Identity-Server.md)**

This document assumes that you have already created an ASP.NET Core based
project (including Module Zero) from the [startup templates](/Templates) and
have set it up to work. We created an [ASP.NET Core MVC startup
project](/Pages/Documents/Zero/Startup-Template-Core) for this demonstration.

### Installation

There are two NuGet packages:

-   [**Abp.ZeroCore.IdentityServer4.vNext**](https://www.nuget.org/packages/Abp.ZeroCore.IdentityServer4.vNext)
    is the main integration package.
-   [**Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore**](https://www.nuget.org/packages/Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore)
    is the storage provider for EF Core.

Since the EF Core package already depends on the first one, you only have to
install the
[**Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore**](https://www.nuget.org/packages/Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore)
package to your project. Install it to the project that contains your
DbContext (.EntityFrameworkCore project for default templates):

    Install-Package Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore

Then you can add a dependency to your [module](../Module-System.md)
(generally, to your EntityFrameworkCore project):

    [DependsOn(typeof(AbpZeroCoreIdentityServervNextEntityFrameworkCoreModule))]
    public class MyModule : AbpModule
    {
        //...
    }

### Configuration

Configuring and using IdentityServer4 with Abp.ZeroCore is similar to
independently using IdentityServer4. You should read its [own
documentation](https://identityserver4.readthedocs.io) to better understand how
it works. In this document, we only show the additional configuration needed
to integrate it into Abp.ZeroCore.

#### Startup Class

In the ASP.NET Core **Startup class**, we must add IdentityServer to the
**service collection** and to the ASP.NET Core **middleware pipeline**.
Highlighted, here are the **differences** from the standard IdentityServer4 usage:

    public class Startup
    {
        public void ConfigureServices(IServiceCollection services)
        {
            //...
    
            services.AddIdentityServer()
                .AddDeveloperSigningCredential()
                .AddInMemoryIdentityResources(IdentityServerConfig.GetIdentityResources())
                .AddInMemoryApiScopes(IdentityServerConfig.GetApiScopes())
                .AddInMemoryApiResources(IdentityServerConfig.GetApiResources())
                .AddInMemoryClients(IdentityServerConfig.GetClients())
                .AddAbpPersistedGrants<IAbpPersistedGrantDbContext>()
                .AddAbpIdentityServer<User>();
    
            //...
        }
    
        public void Configure(IApplicationBuilder app)
        {
            //...
    
                app.UseJwtTokenMiddleware("IdentityBearer");
                app.UseIdentityServer();
    
            //...
        }
    }

We added **services.AddIdentityServer()** just after
**IdentityRegistrar.Register(services)** and added
**app.UseJwtTokenMiddleware("IdentityBearer")** just after
**app.UseAuthentication()** in the startup project.

#### IdentityServerConfig Class

We have used the IdentityServerConfig class to get identity resources, api
resources and clients. You can find more information about this class in
its own
[documentation](http://docs.identityserver.io/en/latest/quickstarts/1_client_credentials.html).
For the simplest case, it can be a static class like below:

    public static class IdentityServerConfig
    {
        public static IEnumerable<IdentityResource> GetIdentityResources()
        {
            return new List<IdentityResource>
            {
                new IdentityResources.OpenId(),
                new IdentityResources.Profile(),
                new IdentityResources.Email(),
                new IdentityResources.Phone()
            };
        }

        public static IEnumerable<ApiScope> GetApiScopes()
        {
            return new List<ApiScope>
            {
                new ApiScope("default-api-scope")
            };
        }

        public static IEnumerable<ApiResource> GetApiResources()
        {
            return new List<ApiResource>
            {
                new ApiResource("default-api-resource", "Default (all) API")
                {
                    Scopes = { "default-api-scope" }
                }
            };
        }

        public static IEnumerable<Client> GetClients()
        {
            return new List<Client>
            {
                new Client
                {
                    ClientId = "client",
                    AllowedGrantTypes = GrantTypes.ClientCredentials.Union(GrantTypes.ResourceOwnerPassword).ToList(),
                    AllowedScopes = {"default-api-scope"},
                    ClientSecrets =
                    {
                        new Secret("secret".Sha256())
                    }
                }
            };
        }
    }

#### DbContext Changes

The **AddAbpPersistedGrants()** method is used to save consent responses to
the persistent data store. In order to use it, **YourDbContext** must
implement the **IAbpPersistedGrantDbContext** interface as shown below:

    public class YourDbContext : AbpZeroDbContext<Tenant, Role, User, YourDbContext>, IAbpPersistedGrantDbContext
    {
        public DbSet<PersistedGrantEntity> PersistedGrants { get; set; }
    
        public YourDbContext(DbContextOptions<YourDbContext> options)
            : base(options)
        {
        }
    
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
    
            modelBuilder.ConfigurePersistedGrantEntity();
        }
    }

The IAbpPersistedGrantDbContext interface defines the **PersistedGrants** DbSet. We also
must call the modelBuilder.**ConfigurePersistedGrantEntity()** extension
method as shown above in order to configure EntityFramework for the
**PersistedGrantEntity**.

Note that this change in YourDbContext causes a new database migration.
So remember to use the "Add-Migration" and "Update-Database" commands to
update your database.

IdentityServer4 will continue to work even if you don't call the
AddAbpPersistedGrants&lt;YourDbContext&gt;() extension method, but user
consent responses will be stored in an in-memory data store in that case
(which is cleared when you restart your application!).

#### JWT Authentication Middleware

If we want to authorize clients against the same application we can use the
[IdentityServer authentication
middleware](https://identityserver4.readthedocs.io/en/latest/topics/apis.html?highlight=UseIdentityServerAuthentication#the-identityserver-authentication-middleware)
for that.

First, install the IdentityServer4.AccessTokenValidation package from NuGet
to your project:

    Install-Package IdentityServer4.AccessTokenValidation

We can then add the middleware to the Startup class as shown below:

    services.AddAuthentication().AddIdentityServerAuthentication("IdentityBearer", options =>
    {
        options.Authority = "https://localhost:44388/";
        options.RequireHttpsMetadata = false;
    });

We added this just after the **services.AddIdentityServer()** line in the startup
project.

### Testing

Our identity server is now ready to get requests from clients. We can
create a console application to make requests and get responses.

-   Create a new **Console Application** inside your solution.
-   Add the **IdentityModel** NuGet package to the console application. This
    package is used to create clients for OAuth endpoints.

While the **IdentityModel** NuGet package is enough to create a client and
consume your API, we need to use the API in a more type safe way: We
will convert incoming data to DTOs which are returned by the application services.

-   Add a reference to the **Application** layer from the console application.
    This will allow us to use the same DTO classes returned by the
    application layer on the client-side.
-   Add the **Abp.Web.Common** NuGet package. This will allow us to use
    the AjaxResponse class defined in ASP.NET Boilerplate. Otherwise,
    we will have to deal with raw JSON strings to handle the server response.

Change Program.cs as shown below:

    using System;
    using System.Net.Http;
    using System.Threading.Tasks;
    using Abp.Application.Services.Dto;
    using Abp.Web.Models;
    using IdentityModel.Client;
    using Newtonsoft.Json;

    namespace IdentityServerIntegrationDemo.ConsoleApiClient
    {
        class Program
        {
            static void Main(string[] args)
            {
                RunDemoAsync().Wait();
                Console.ReadLine();
            }

            public static async Task RunDemoAsync()
            {
                var accessToken = await GetAccessTokenViaOwnerPasswordAsync();
                await GetUsersListAsync(accessToken);
            }

            private static async Task<string> GetAccessTokenViaOwnerPasswordAsync()
            {
                var disco =  await new HttpClient().GetDiscoveryDocumentAsync("https://localhost:44388");

                var tokenClient = new HttpClient();
                tokenClient.DefaultRequestHeaders.Add("Abp.TenantId", "1");
                var tokenResponse = await tokenClient.RequestPasswordTokenAsync(new PasswordTokenRequest()
                {
                    Address = disco.TokenEndpoint,
                    ClientId = "client",
                    ClientSecret = "secret",
                    UserName = "admin",
                    Password = "123qwe"
                });

                if (tokenResponse.IsError)
                {
                    Console.WriteLine("Error: ");
                    Console.WriteLine(tokenResponse.Error);
                }

                Console.WriteLine(tokenResponse.Json);

                return tokenResponse.AccessToken;
            }

            private static async Task GetUsersListAsync(string accessToken)
            {
                var client = new HttpClient();
                client.SetBearerToken(accessToken);

                var response = await client.GetAsync("https://localhost:44388/api/services/app/user/GetAll");
                if (!response.IsSuccessStatusCode)
                {
                    Console.WriteLine(response.StatusCode);
                    return;
                }

                var content = await response.Content.ReadAsStringAsync();
                var ajaxResponse = JsonConvert.DeserializeObject<AjaxResponse<PagedResultDto<UserListDto>>>(content);
                if (!ajaxResponse.Success)
                {
                    throw new Exception(ajaxResponse.Error?.Message ?? "Remote service throws exception!");
                }

                Console.WriteLine();
                Console.WriteLine("Total user count: " + ajaxResponse.Result.TotalCount);
                Console.WriteLine();
                foreach (var user in ajaxResponse.Result.Items)
                {
                    Console.WriteLine($"### UserId: {user.Id}, UserName: {user.UserName}");
                    Console.WriteLine(JsonConvert.SerializeObject(user, Formatting.Indented));
                }
            }
        }

        internal class UserListDto
        {
            public int Id { get; set; }
            public string UserName { get; set; }
        }
    }

Before running this application, ensure that your web project set up and
running, because this console application will make a request to the web
application. Also, ensure that the requesting port (44388) is the same
as your web application.
