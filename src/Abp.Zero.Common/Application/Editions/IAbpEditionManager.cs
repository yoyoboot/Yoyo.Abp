using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Application.Features;
using Abp.Runtime.Caching;

namespace Abp.Application.Editions;

public interface IAbpEditionManager
{
    IQueryable<Edition> Editions { get; }

    ICacheManager CacheManager { get; set; }
    IFeatureManager FeatureManager { get; set; }

    Task<IQueryable<Edition>> GetEditionsAsync();
    Task<string> GetFeatureValueOrNullAsync(string editionId, string featureName);
    string GetFeatureValueOrNull(string editionId, string featureName);
    Task SetFeatureValueAsync(string editionId, string featureName, string value);
    void SetFeatureValue(string editionId, string featureName, string value);
    Task<IReadOnlyList<NameValue>> GetFeatureValuesAsync(string editionId);
    IReadOnlyList<NameValue> GetFeatureValues(string editionId);
    Task SetFeatureValuesAsync(string editionId, params NameValue[] values);
    void SetFeatureValues(string editionId, params NameValue[] values);
    Task CreateAsync(Edition edition);
    void Create(Edition edition);
    Task<Edition> FindByNameAsync(string name);
    Edition FindByName(string name);
    Task<Edition> FindByIdAsync(string id);
    Edition FindById(string id);
    Task<Edition> GetByIdAsync(string id);
    Edition GetById(string id);
    Task DeleteAsync(Edition edition);
    void Delete(Edition edition);
}
