using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Domain.Repositories;
using Abp.Domain.Services;
using Abp.Domain.Uow;
using Abp.Linq;
using Abp.UI;
using Abp.Zero;

namespace Abp.Organizations
{
    /// <summary>
    /// Performs domain logic for Organization Units.
    /// </summary>
    public class OrganizationUnitManager : DomainService
    {
        protected IRepository<OrganizationUnit, string> OrganizationUnitRepository { get; private set; }

        public IAsyncQueryableExecuter AsyncQueryableExecuter { get; set; }
        
        public OrganizationUnitManager(IRepository<OrganizationUnit, string> organizationUnitRepository)
        {
            OrganizationUnitRepository = organizationUnitRepository;

            LocalizationSourceName = AbpZeroConsts.LocalizationSourceName;
            AsyncQueryableExecuter = NullAsyncQueryableExecuter.Instance;
        }
        
        public virtual async Task CreateAsync(OrganizationUnit organizationUnit)
        {
            using (var uow = UnitOfWorkManager.Begin())
            {
                organizationUnit.Code = await GetNextChildCodeAsync(organizationUnit.ParentId);
                await ValidateOrganizationUnitAsync(organizationUnit);
                await OrganizationUnitRepository.InsertAsync(organizationUnit);

                await uow.CompleteAsync();
            }    
        }
        
        public virtual void Create(OrganizationUnit organizationUnit)
        {
            using (var uow = UnitOfWorkManager.Begin())
            {
                organizationUnit.Code = GetNextChildCode(organizationUnit.ParentId);
                ValidateOrganizationUnit(organizationUnit);
                OrganizationUnitRepository.Insert(organizationUnit);
                
                uow.Complete();
            }
        }

        public virtual async Task UpdateAsync(OrganizationUnit organizationUnit)
        {
            await ValidateOrganizationUnitAsync(organizationUnit);
            await OrganizationUnitRepository.UpdateAsync(organizationUnit);
        }

        public virtual void Update(OrganizationUnit organizationUnit)
        {
            ValidateOrganizationUnit(organizationUnit);
            OrganizationUnitRepository.Update(organizationUnit);
        }

        public virtual async Task<string> GetNextChildCodeAsync(string parentId)
        {
            var lastChild = await GetLastChildOrNullAsync(parentId);
            if (lastChild == null)
            {
                var parentCode = parentId != null ? await GetCodeAsync(parentId) : null;
                return OrganizationUnit.AppendCode(parentCode, OrganizationUnit.CreateCode(1));
            }

            return OrganizationUnit.CalculateNextCode(lastChild.Code);
        }

        public virtual string GetNextChildCode(string parentId)
        {
            var lastChild = GetLastChildOrNull(parentId);
            if (lastChild == null)
            {
                var parentCode = parentId != null ? GetCode(parentId) : null;
                return OrganizationUnit.AppendCode(parentCode, OrganizationUnit.CreateCode(1));
            }

            return OrganizationUnit.CalculateNextCode(lastChild.Code);
        }

        public virtual async Task<OrganizationUnit> GetLastChildOrNullAsync(string parentId)
        {
            var query = OrganizationUnitRepository.GetAll()
                .Where(ou => ou.ParentId == parentId)
                .OrderByDescending(ou => ou.Code);
            return await AsyncQueryableExecuter.FirstOrDefaultAsync(query);
        }

        public virtual OrganizationUnit GetLastChildOrNull(string parentId)
        {
            var query = OrganizationUnitRepository.GetAll()
                .Where(ou => ou.ParentId == parentId)
                .OrderByDescending(ou => ou.Code);
            return query.FirstOrDefault();
        }

        public virtual async Task<string> GetCodeAsync(string id)
        {
            return (await OrganizationUnitRepository.GetAsync(id)).Code;
        }

        public virtual string GetCode(string id)
        {
            return (OrganizationUnitRepository.Get(id)).Code;
        }
        
        public virtual async Task DeleteAsync(string id)
        {
            using (var uow = UnitOfWorkManager.Begin())
            {
                var children = await FindChildrenAsync(id, true);

                foreach (var child in children)
                {
                    await OrganizationUnitRepository.DeleteAsync(child);
                }

                await OrganizationUnitRepository.DeleteAsync(id);

                await uow.CompleteAsync();
            }
        }

        public virtual void Delete(string id)
        {
            using (var uow = UnitOfWorkManager.Begin())
            {
                var children = FindChildren(id, true);

                foreach (var child in children)
                {
                    OrganizationUnitRepository.Delete(child);
                }

                OrganizationUnitRepository.Delete(id);
                
                uow.Complete();
            }
        }

        public virtual async Task MoveAsync(string id, string parentId)
        {
            using (var uow = UnitOfWorkManager.Begin())
            {
                var organizationUnit = await OrganizationUnitRepository.GetAsync(id);
                if (organizationUnit.ParentId == parentId)
                {
                    await uow.CompleteAsync();
                    return;
                }

                //Should find children before Code change
                var children = await FindChildrenAsync(id, true);

                //Store old code of OU
                var oldCode = organizationUnit.Code;

                //Move OU
                organizationUnit.Code = await GetNextChildCodeAsync(parentId);
                organizationUnit.ParentId = parentId;

                await ValidateOrganizationUnitAsync(organizationUnit);

                //Update Children Codes
                foreach (var child in children)
                {
                    child.Code = OrganizationUnit.AppendCode(organizationUnit.Code, OrganizationUnit.GetRelativeCode(child.Code, oldCode));
                }
                
                await uow.CompleteAsync();
            }
        }

        public virtual void Move(string id, string parentId)
        {
            UnitOfWorkManager.WithUnitOfWork(() =>
            {
                var organizationUnit = OrganizationUnitRepository.Get(id);
                if (organizationUnit.ParentId == parentId)
                {
                    return;
                }

                //Should find children before Code change
                var children = FindChildren(id, true);

                //Store old code of OU
                var oldCode = organizationUnit.Code;

                //Move OU
                organizationUnit.Code = GetNextChildCode(parentId);
                organizationUnit.ParentId = parentId;

                ValidateOrganizationUnit(organizationUnit);

                //Update Children Codes
                foreach (var child in children)
                {
                    child.Code = OrganizationUnit.AppendCode(organizationUnit.Code, OrganizationUnit.GetRelativeCode(child.Code, oldCode));
                }
            });
        }

        public async Task<List<OrganizationUnit>> FindChildrenAsync(string parentId, bool recursive = false)
        {
            if (!recursive)
            {
                return await OrganizationUnitRepository.GetAllListAsync(ou => ou.ParentId == parentId);
            }

            if (!parentId.HasValue())
            {
                return await OrganizationUnitRepository.GetAllListAsync();
            }

            var code = await GetCodeAsync(parentId);

            return await OrganizationUnitRepository.GetAllListAsync(
                ou => ou.Code.StartsWith(code) && ou.Id != parentId
            );
        }

        public List<OrganizationUnit> FindChildren(string parentId, bool recursive = false)
        {
            if (!recursive)
            {
                return OrganizationUnitRepository.GetAllList(ou => ou.ParentId == parentId);
            }

            if (!parentId.HasValue())
            {
                return OrganizationUnitRepository.GetAllList();
            }

            var code = GetCode(parentId);

            return OrganizationUnitRepository.GetAllList(
                ou => ou.Code.StartsWith(code) && ou.Id != parentId
            );
        }

        protected virtual async Task ValidateOrganizationUnitAsync(OrganizationUnit organizationUnit)
        {
            var siblings = (await FindChildrenAsync(organizationUnit.ParentId))
                .Where(ou => ou.Id != organizationUnit.Id)
                .ToList();

            if (siblings.Any(ou => ou.DisplayName == organizationUnit.DisplayName))
            {
                throw new UserFriendlyException(L("OrganizationUnitDuplicateDisplayNameWarning", organizationUnit.DisplayName));
            }
        }

        protected virtual void ValidateOrganizationUnit(OrganizationUnit organizationUnit)
        {
            var siblings = (FindChildren(organizationUnit.ParentId))
                .Where(ou => ou.Id != organizationUnit.Id)
                .ToList();

            if (siblings.Any(ou => ou.DisplayName == organizationUnit.DisplayName))
            {
                throw new UserFriendlyException(L("OrganizationUnitDuplicateDisplayNameWarning", organizationUnit.DisplayName));
            }
        }
    }
}
