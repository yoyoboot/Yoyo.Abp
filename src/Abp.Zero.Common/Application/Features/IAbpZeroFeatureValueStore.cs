using System.Threading.Tasks;

namespace Abp.Application.Features
{
    public interface IAbpZeroFeatureValueStore : IFeatureValueStore
    {
        Task<string> GetValueOrNullAsync(string tenantId, string featureName);
        string GetValueOrNull(string tenantId, string featureName);
        Task<string> GetEditionValueOrNullAsync(string editionId, string featureName);
        string GetEditionValueOrNull(string editionId, string featureName);
        Task SetEditionFeatureValueAsync(string editionId, string featureName, string value);
        void SetEditionFeatureValue(string editionId, string featureName, string value);
    }
}
