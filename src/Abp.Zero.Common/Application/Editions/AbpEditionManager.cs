using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Application.Features;
using Abp.Collections.Extensions;
using Abp.Domain.Repositories;
using Abp.Domain.Services;
using Abp.Domain.Uow;
using Abp.Runtime.Caching;

namespace Abp.Application.Editions
{
    public class AbpEditionManager : IDomainService
    {
        private readonly IAbpZeroFeatureValueStore _featureValueStore;
        private readonly IUnitOfWorkManager _unitOfWorkManager;
        
        public IQueryable<Edition> Editions => EditionRepository.GetAll();

        public ICacheManager CacheManager { get; set; }

        public IFeatureManager FeatureManager { get; set; }

        protected IRepository<Edition> EditionRepository { get; set; }

        public AbpEditionManager(
            IRepository<Edition> editionRepository,
            IAbpZeroFeatureValueStore featureValueStore, 
            IUnitOfWorkManager unitOfWorkManager)
        {
            _featureValueStore = featureValueStore;
            _unitOfWorkManager = unitOfWorkManager;
            EditionRepository = editionRepository;
        }

        public virtual Task<string> GetFeatureValueOrNullAsync(string editionId, string featureName)
        {
            return _featureValueStore.GetEditionValueOrNullAsync(editionId, featureName);
        }

        public virtual string GetFeatureValueOrNull(string editionId, string featureName)
        {
            return _featureValueStore.GetEditionValueOrNull(editionId, featureName);
        }

        public virtual Task SetFeatureValueAsync(string editionId, string featureName, string value)
        {
            return _featureValueStore.SetEditionFeatureValueAsync(editionId, featureName, value);
        }

        public virtual void SetFeatureValue(string editionId, string featureName, string value)
        {
            _featureValueStore.SetEditionFeatureValue(editionId, featureName, value);
        }

        public virtual async Task<IReadOnlyList<NameValue>> GetFeatureValuesAsync(string editionId)
        {
            var values = new List<NameValue>();

            foreach (var feature in FeatureManager.GetAll())
            {
                values.Add(new NameValue(feature.Name, await GetFeatureValueOrNullAsync(editionId, feature.Name) ?? feature.DefaultValue));
            }

            return values;
        }

        public virtual IReadOnlyList<NameValue> GetFeatureValues(string editionId)
        {
            var values = new List<NameValue>();

            foreach (var feature in FeatureManager.GetAll())
            {
                values.Add(new NameValue(feature.Name, GetFeatureValueOrNull(editionId, feature.Name) ?? feature.DefaultValue));
            }

            return values;
        }

        public virtual async Task SetFeatureValuesAsync(string editionId, params NameValue[] values)
        {
            if (values.IsNullOrEmpty())
            {
                return;
            }

            foreach (var value in values)
            {
                await SetFeatureValueAsync(editionId, value.Name, value.Value);
            }
        }

        public virtual void SetFeatureValues(string editionId, params NameValue[] values)
        {
            if (values.IsNullOrEmpty())
            {
                return;
            }

            foreach (var value in values)
            {
                SetFeatureValue(editionId, value.Name, value.Value);
            }
        }

        public virtual async Task CreateAsync(Edition edition)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
                await EditionRepository.InsertAsync(edition)
            );
        }

        public virtual void Create(Edition edition)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                EditionRepository.Insert(edition);
            });
        }

        public virtual async Task<Edition> FindByNameAsync(string name)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
            {
                return await EditionRepository.FirstOrDefaultAsync(edition => edition.Name == name);
            });
        }

        public virtual Edition FindByName(string name)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
            {
                return EditionRepository.FirstOrDefault(edition => edition.Name == name);
            });
        }

        public virtual async Task<Edition> FindByIdAsync(string id)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
                await EditionRepository.FirstOrDefaultAsync(id)
            );
        }

        public virtual Edition FindById(string id)
        {
            return _unitOfWorkManager.WithUnitOfWork(() =>
                EditionRepository.FirstOrDefault(id)
            );
        }

        public virtual async Task<Edition> GetByIdAsync(string id)
        {
            return await _unitOfWorkManager.WithUnitOfWorkAsync(async () =>
                await EditionRepository.GetAsync(id)
            );
        }

        public virtual Edition GetById(string id)
        {
            return _unitOfWorkManager.WithUnitOfWork(() => EditionRepository.Get(id));
        }

        public virtual async Task DeleteAsync(Edition edition)
        {
            await _unitOfWorkManager.WithUnitOfWorkAsync(async () => await EditionRepository.DeleteAsync(edition));
        }

        public virtual void Delete(Edition edition)
        {
            _unitOfWorkManager.WithUnitOfWork(() =>
            {
                EditionRepository.Delete(edition);
            });
        }
    }
}
