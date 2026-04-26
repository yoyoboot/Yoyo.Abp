using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Authorization.Users;

namespace Abp.MultiTenancy;

public interface IAbpTenantManager<TTenant, TUser>
    where TTenant : AbpTenant<TUser>
    where TUser : AbpUserBase
{
    IQueryable<TTenant> Tenants { get; }

    Task CreateAsync(TTenant tenant);
    void Create(TTenant tenant);
    Task UpdateAsync(TTenant tenant);
    void Update(TTenant tenant);
    Task<TTenant> FindByIdAsync(string id);
    TTenant FindById(string id);
    Task<TTenant> GetByIdAsync(string id);
    TTenant GetById(string id);
    Task<TTenant> FindByTenancyNameAsync(string tenancyName);
    TTenant FindByTenancyName(string tenancyName);
    Task DeleteAsync(TTenant tenant);
    void Delete(TTenant tenant);
    Task<string> GetFeatureValueOrNullAsync(string tenantId, string featureName);
    string GetFeatureValueOrNull(string tenantId, string featureName);
    Task<IReadOnlyList<NameValue>> GetFeatureValuesAsync(string tenantId);
    IReadOnlyList<NameValue> GetFeatureValues(string tenantId);
    Task SetFeatureValuesAsync(string tenantId, params NameValue[] values);
    void SetFeatureValues(string tenantId, params NameValue[] values);
    Task SetFeatureValueAsync(string tenantId, string featureName, string value);
    void SetFeatureValue(string tenantId, string featureName, string value);
    Task ResetAllFeaturesAsync(string tenantId);
    void ResetAllFeatures(string tenantId);
}
