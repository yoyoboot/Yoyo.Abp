using System.Reflection;
using System.Security.Claims;
using Abp.AspNetCore.OpenIddict.Controllers;
using Abp.Authorization.Roles;
using Abp.Authorization.Users;
using Abp.MultiTenancy;
using Abp.Runtime.Security;
using Shouldly;
using Xunit;

namespace Abp.AspNetCore.Tests.OpenIddict;

public class TokenController_StringKey_Tests
{
    [Fact]
    public void FindTenantId_Should_Keep_String_Tenant_Claim_For_String_Key_Fork()
    {
        var controller = new TokenController<TestTenant, TestRole, TestUser>(
            signInManager: null,
            userManager: null,
            applicationManager: null,
            authorizationManager: null,
            scopeManager: null,
            tokenManager: null,
            openIddictClaimsPrincipalManager: null
        );
        var principal = new ClaimsPrincipal(new ClaimsIdentity(new[]
        {
            new Claim(AbpClaimTypes.TenantId, "tenant-001")
        }));

        var result = typeof(TokenController<TestTenant, TestRole, TestUser>)
            .GetMethod("FindTenantId", BindingFlags.Instance | BindingFlags.NonPublic)
            !.Invoke(controller, new object[] { principal });

        result.ShouldBe("tenant-001");
    }

    private class TestTenant : AbpTenant<TestUser>
    {
    }

    private class TestRole : AbpRole<TestUser>
    {
    }

    private class TestUser : AbpUser<TestUser>
    {
    }
}
