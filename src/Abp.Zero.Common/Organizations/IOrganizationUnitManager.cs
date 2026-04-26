using System.Collections.Generic;
using System.Threading.Tasks;

namespace Abp.Organizations;

public interface IOrganizationUnitManager
{
    Task CreateAsync(OrganizationUnit organizationUnit);
    void Create(OrganizationUnit organizationUnit);
    Task UpdateAsync(OrganizationUnit organizationUnit);
    void Update(OrganizationUnit organizationUnit);
    Task<string> GetNextChildCodeAsync(string parentId);
    string GetNextChildCode(string parentId);
    Task<OrganizationUnit> GetLastChildOrNullAsync(string parentId);
    OrganizationUnit GetLastChildOrNull(string parentId);
    Task<string> GetCodeAsync(string id);
    string GetCode(string id);
    Task DeleteAsync(string id);
    void Delete(string id);
    Task MoveAsync(string id, string parentId);
    void Move(string id, string parentId);
    Task<List<OrganizationUnit>> FindChildrenAsync(string parentId, bool recursive = false);
    List<OrganizationUnit> FindChildren(string parentId, bool recursive = false);
}
