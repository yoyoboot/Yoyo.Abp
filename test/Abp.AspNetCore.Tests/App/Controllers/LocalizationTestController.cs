using Abp.AspNetCore.Localization;
using Abp.AspNetCore.Mvc.Controllers;

namespace Abp.AspNetCore.App.Controllers;

public class LocalizationTestController : AbpController
{
    public string GetAbpLocalizationHeaderRequestCultureProviderHeaderName()
    {
        return AbpLocalizationHeaderRequestCultureProvider.HeaderName;
    }
}
