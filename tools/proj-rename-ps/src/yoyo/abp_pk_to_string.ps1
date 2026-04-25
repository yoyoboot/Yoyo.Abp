
# 执行公用脚本
. '.\common.ps1'
. '.\func.ps1'


# 替换类库的
function ReplaceEntitys {
    param (
        [string]$path
    )

    # 读取文件内容
    $content = ReadFile -Path $path
     
    ## 可见级别替换
    $matches = [Regex]::Matches($content, '(InternalsVisibleTo\(")(Abp.*?)"\)')
    foreach ($match in $matches) {
        if ($match.Success -and $match.Groups.Count -eq 3 -and $match.Groups[2].Value.EndsWith('.Tests') -eq $false) {
            $oldVal = $match.Groups[1].Value + $match.Groups[2].Value
            $newVal = $match.Groups[1].Value + 'Yoyo.' + $match.Groups[2].Value
            $content = $content -creplace [Regex]::Escape($oldVal), $newVal
        }
    }

    $content = $content -creplace [Regex]::Escape('Entity<long>'), 'Entity<string>'
    $content = $content -creplace [Regex]::Escape('Entity<int>'), 'Entity<string>'
    $content = $content -creplace [Regex]::Escape('AggregateRoot<int>'), 'AggregateRoot<string>'
    $content = $content -creplace [Regex]::Escape('EntityDto<long?>'), 'EntityDto<string>'
    $content = $content -creplace [Regex]::Escape('EntityDto<long>'), 'EntityDto<string>'
    $content = $content -creplace [Regex]::Escape('EntityDto<int?>'), 'EntityDto<string>'
    $content = $content -creplace [Regex]::Escape('EntityDto<int>'), 'EntityDto<string>'
    $content = $content -creplace [Regex]::Escape('EntityDto(int id)'), 'EntityDto(string id)'

    $content = $content -creplace [Regex]::Escape('EntityCache<TCacheItem, int>'), 'EntityCache<TCacheItem, string>'
    $content = $content -creplace [Regex]::Escape('EntityCache<TEntity, TCacheItem, int>'), 'EntityCache<TEntity, TCacheItem, string>'

    $content = $content -creplace [Regex]::Escape('AsyncCrudAppService<TEntityDto, int'), 'AsyncCrudAppService<TEntityDto, string'
    $content = $content -creplace [Regex]::Escape('CrudAppService<TEntity, TEntityDto, int'), 'CrudAppService<TEntity, TEntityDto, string'
    $content = $content -creplace [Regex]::Escape('CrudAppService<TEntityDto, int'), 'CrudAppService<TEntityDto, string'

    $content = $content -creplace [Regex]::Escape('Repository<TEntity, int>'), 'Repository<TEntity, string>'
    $content = $content -creplace [Regex]::Escape('Repository<EntityChange, long>'), 'Repository<EntityChange, string>'
    $content = $content -creplace [Regex]::Escape('RepositoryBase<TEntity, int>'), 'RepositoryBase<TEntity, string>'
    $content = $content -creplace [Regex]::Escape('RepositoryBase<TDbContext, TEntity, int>'), 'RepositoryBase<TDbContext, TEntity, string>'
    $content = $content -creplace [Regex]::Escape('BatchDeleteAsync<TEntity, int>'), 'BatchDeleteAsync<TEntity, string>'
    $content = $content -creplace [Regex]::Escape('BatchUpdateAsync<TEntity, int>'), 'BatchUpdateAsync<TEntity, string>'

    ### zero repo
    $content = $content -creplace [Regex]::Escape('Repository<TenantFeatureSetting, long>'), 'Repository<TenantFeatureSetting, string>'
    $content = $content -creplace [Regex]::Escape('Repository<EditionFeatureSetting, long>'), 'Repository<EditionFeatureSetting, string>'
    $content = $content -creplace [Regex]::Escape('Repository<AuditLog, long>'), 'Repository<AuditLog, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserOrganizationUnit, long>'), 'Repository<UserOrganizationUnit, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserAccount, long>'), 'Repository<UserAccount, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserRole, long>'), 'Repository<UserRole, string>'
    $content = $content -creplace [Regex]::Escape('Repository<BackgroundJobInfo, long>'), 'Repository<BackgroundJobInfo, string>'
    $content = $content -creplace [Regex]::Escape('Repository<Setting, long>'), 'Repository<Setting, string>'
    $content = $content -creplace [Regex]::Escape('Repository<DynamicEntityPropertyValue, long>'), 'Repository<DynamicEntityPropertyValue, string>'
    $content = $content -creplace [Regex]::Escape('Repository<DynamicPropertyValue, long>'), 'Repository<DynamicPropertyValue, string>'
    $content = $content -creplace [Regex]::Escape('Repository<EntityChangeSet, long>'), 'Repository<EntityChangeSet, string>'
    $content = $content -creplace [Regex]::Escape('Repository<ApplicationLanguageText, long>'), 'Repository<ApplicationLanguageText, string>'
    $content = $content -creplace [Regex]::Escape('Repository<OrganizationUnit, long>'), 'Repository<OrganizationUnit, string>'
    $content = $content -creplace [Regex]::Escape('Repository<OrganizationUnitRole, long>'), 'Repository<OrganizationUnitRole, string>'
    $content = $content -creplace [Regex]::Escape('Repository<OrganizationUnitUser, long>'), 'Repository<OrganizationUnitUser, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserLoginAttempt, long>'), 'Repository<UserLoginAttempt, string>'
    $content = $content -creplace [Regex]::Escape('Repository<RolePermissionSetting, long>'), 'Repository<RolePermissionSetting, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserLogin, long>'), 'Repository<UserLogin, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserClaim, long>'), 'Repository<UserClaim, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserPermissionSetting, long>'), 'Repository<UserPermissionSetting, string>'
    $content = $content -creplace [Regex]::Escape('Repository<UserToken, long>'), 'Repository<UserToken, string>'
    $content = $content -creplace [Regex]::Escape('Repository<TUser, long>'), 'Repository<TUser, string>'


    $content = $content -creplace [Regex]::Escape('long? DeleterUserId'), 'string DeleterUserId'
    $content = $content -creplace [Regex]::Escape('long? LastModifierUserId'), 'string LastModifierUserId'
    $content = $content -creplace [Regex]::Escape('long? CreatorUserId'), 'string CreatorUserId'
    $content = $content -creplace [Regex]::Escape('long EntityChangeId'), 'string EntityChangeId'
    $content = $content -creplace [Regex]::Escape('long EntityChangeSetId'), 'string EntityChangeSetId'

    $content = $content -creplace [Regex]::Escape('long OrganizationUnitId'), 'string OrganizationUnitId'
    $content = $content -creplace [Regex]::Escape('long organizationUnitId'), 'string organizationUnitId'
    $content = $content -creplace [Regex]::Escape('long ouId'), 'string ouId'
    $content = $content -creplace [Regex]::Escape('long[] organizationUnitIds'), 'string[] organizationUnitIds'
    $content = $content -creplace [Regex]::Escape('organizationUnitIds = new long[0]'), 'organizationUnitIds = new string[0]'

    ## 租户id
    $content = $content -creplace [Regex]::Escape('int DefaultTenantId = 1'), 'string DefaultTenantId = "1"'
    $content = $content -creplace [Regex]::Escape('GetTenantId().HasValue'), 'GetTenantId().HasValue()'
    $content = $content -creplace [Regex]::Escape('TenantId.HasValue'), 'TenantId.HasValue()'
    $content = $content -creplace [Regex]::Escape('tenantId.HasValue'), 'tenantId.HasValue()'
    $content = $content -creplace [Regex]::Escape('_tenantId.HasValue'), '_tenantId.HasValue()'

    $content = $content -creplace [Regex]::Escape('TenantId.Value'), 'TenantId'
    $content = $content -creplace [Regex]::Escape('tenantId.Value'), 'tenantId'
    $content = $content -creplace [Regex]::Escape('_tenantId.Value'), '_tenantId'
    $content = $content -creplace [Regex]::Escape('TenantId?.ToString()'), 'TenantId'
    $content = $content -creplace [Regex]::Escape('tenantId?.ToString()'), 'tenantId'
    $content = $content -creplace [Regex]::Escape('_tenantId?.ToString()'), '_tenantId'

    $content = $content -creplace [Regex]::Escape('int TenantId'), 'string TenantId'
    $content = $content -creplace [Regex]::Escape('int? TenantId'), 'string TenantId'
    $content = $content -creplace [Regex]::Escape('int tenantId'), 'string tenantId'
    $content = $content -creplace [Regex]::Escape('int? tenantId'), 'string tenantId'
    $content = $content -creplace [Regex]::Escape('int? _tenantId'), 'string _tenantId'
    $content = $content -creplace [Regex]::Escape('int? notificationId'), 'string notificationId'
    $content = $content -creplace [Regex]::Escape('int? expectedTenantId'), 'string expectedTenantId'

    $content = $content -creplace [Regex]::Escape('int?[] tenantIds'), 'string[] tenantIds'
    $content = $content -creplace [Regex]::Escape('List<int> tenantIds'), 'List<string> tenantIds'
    $content = $content -creplace [Regex]::Escape('var featureGrantedTenants = new List<int?>()'), 'var featureGrantedTenants = new List<string>()'
    $content = $content -creplace [Regex]::Escape('int? ResolveTenantId'), 'string ResolveTenantId'
    $content = $content -creplace [Regex]::Escape('Task<int?> ResolveTenantIdAsync()'), 'Task<string> ResolveTenantIdAsync()'
    $content = $content -creplace [Regex]::Escape('tenantId ?? 0'), 'tenantId ?? "0"'
    $content = $content -creplace [Regex]::Escape('TenantId ?? 0'), 'TenantId ?? "0"'
    $content = $content -creplace [Regex]::Escape('TenantId() ?? 0'), 'TenantId() ?? "0"'
    $content = $content -creplace [Regex]::Escape('Convert.ToInt32(tenantIdClaim.Value)'), 'tenantIdClaim.Value'
    $content = $content -creplace [Regex]::Escape('Convert.ToInt32(tenantIdOrNull.Value)'), 'tenantIdOrNull.Value'
    $content = $content -creplace [Regex]::Escape('Convert.ToInt32(tenantIdOrNull)'), 'tenantIdOrNull'
    $content = $content -creplace [Regex]::Escape('int?[] GetTenantIds'), 'string[] GetTenantIds'
    $content = $content -creplace [Regex]::Escape('.Select(tenantIdAsStr => tenantIdAsStr == "null" ? (int?) null : (int?) tenantIdAsStr.To<int>())'), '.Select(tenantIdAsStr => tenantIdAsStr == "null" ? null : tenantIdAsStr)'
    $content = $content -creplace [Regex]::Escape('AllTenantIds.To<int>()'), 'AllTenantIds'
    $content = $content -creplace [Regex]::Escape('int.TryParse(tenantIdHeader.First(), out var tenantId) ? tenantId : (int?) null'), 'tenantIdHeader.FirstOrDefault()'
    $content = $content -creplace [Regex]::Escape('int.TryParse(tenantIdValue, out var tenantId) ? tenantId : (int?) null'), 'tenantIdValue.HasValue() ? tenantIdValue : null'
    $content = $content -creplace [Regex]::Escape('int? currentTenantId'), 'var currentTenantId'
    $content = $content -creplace [Regex]::Escape('int? CurrentTenantId'), 'string CurrentTenantId'
    $content = $content -creplace [Regex]::Escape('tenant == null ? (int?) null'), 'tenant == null ? null'
    $content = $content -creplace [Regex]::Escape('loginResult.Tenant.Id : (int?) null'), 'loginResult.Tenant.Id : null'
    $content = $content -creplace [Regex]::Escape('loginResult.User.Id : (long?) null'), 'loginResult.User.Id : null'
    $content = $content -creplace [Regex]::Escape('<int?> GetVerifiedTenantIdAsync()'), '<string> GetVerifiedTenantIdAsync()'

    ## 用户Id
    $content = $content -creplace [Regex]::Escape('UserId.HasValue'), 'UserId.HasValue()'
    $content = $content -creplace [Regex]::Escape('userId.HasValue'), 'userId.HasValue()'
    $content = $content -creplace [Regex]::Escape('_userId.HasValue'), '_userId.HasValue()'

    $content = $content -creplace [Regex]::Escape('UserId.Value'), 'UserId'
    $content = $content -creplace [Regex]::Escape('userId.Value'), 'userId'
    $content = $content -creplace [Regex]::Escape('_userId.Value'), '_userId'

    $content = $content -creplace [Regex]::Escape('UserId?.ToString()'), 'UserId'
    $content = $content -creplace [Regex]::Escape('userId?.ToString()'), 'userId'
    $content = $content -creplace [Regex]::Escape('_userId?.ToString()'), '_userId'

    $content = $content -creplace [Regex]::Escape('long? UserLinkId'), 'string UserLinkId'
    $content = $content -creplace [Regex]::Escape('long UserId'), 'string UserId'
    $content = $content -creplace [Regex]::Escape('long? _userId'), 'string _userId'
    $content = $content -creplace [Regex]::Escape('long? UserId'), 'string UserId'
    $content = $content -creplace [Regex]::Escape('long userId'), 'string userId'
    $content = $content -creplace [Regex]::Escape('long? userId'), 'string userId'
    $content = $content -creplace [Regex]::Escape('int userId'), 'string userId'
    $content = $content -creplace [Regex]::Escape('int? userId'), 'string userId'
    $content = $content -creplace [Regex]::Escape('long? expectedUserId'), 'string expectedUserId'
    $content = $content -creplace [Regex]::Escape('long? GetUserId'), 'string GetUserId'
    $content = $content -creplace [Regex]::Escape('Convert.ToInt64(userIdOrNull.Value)'), 'userIdOrNull.Value'
    $content = $content -creplace [Regex]::Escape('userId.To<long>()'), 'userId'
    $content = $content -creplace [Regex]::Escape('Repository<User, long>'), 'Repository<User, string>'

    ## 角色Id
    $content = $content -creplace [Regex]::Escape('int? RoleId'), 'string RoleId'
    $content = $content -creplace [Regex]::Escape('int RoleId'), 'string RoleId'
    $content = $content -creplace [Regex]::Escape('int? roleId'), 'string roleId'
    $content = $content -creplace [Regex]::Escape('int roleId'), 'string roleId'
    $content = $content -creplace [Regex]::Escape('long? RoleId'), 'string RoleId'
    $content = $content -creplace [Regex]::Escape('long RoleId'), 'string RoleId'
    $content = $content -creplace [Regex]::Escape('long? roleId'), 'string roleId'
    $content = $content -creplace [Regex]::Escape('long roleId'), 'string roleId'
    $content = $content -creplace [Regex]::Escape('EditionId.HasValue'), 'EditionId.HasValue()'
    $content = $content -creplace [Regex]::Escape('editionId.HasValue'), 'editionId.HasValue()'
    $content = $content -creplace [Regex]::Escape('_editionId.HasValue'), '_editionId.HasValue()'
    $content = $content -creplace [Regex]::Escape('EditionId.Value'), 'EditionId'
    $content = $content -creplace [Regex]::Escape('List<int> RoleIds'), 'List<string> RoleIds'
    $content = $content -creplace [Regex]::Escape('RoleIds = new List<int>'), 'RoleIds = new List<string>'
    $content = $content -creplace [Regex]::Escape('_roleRepository.FirstOrDefault(id.To<int>())'), '_roleRepository.FirstOrDefault(id)'
    $content = $content -creplace [Regex]::Escape('_roleRepository.FirstOrDefaultAsync(id.To<int>())'), '_roleRepository.FirstOrDefaultAsync(id)'
    $content = $content -creplace [Regex]::Escape('int? expectedRoleId'), 'string expectedRoleId'




    ## 模拟登录
    $content = $content -creplace [Regex]::Escape('int? ImpersonatorTenantId'), 'string ImpersonatorTenantId'
    $content = $content -creplace [Regex]::Escape('int ImpersonatorTenantId'), 'string ImpersonatorTenantId'
    $content = $content -creplace [Regex]::Escape('int? impersonatorTenantId'), 'string impersonatorTenantId'
    $content = $content -creplace [Regex]::Escape('int impersonatorTenantId'), 'string impersonatorTenantId'
    $content = $content -creplace [Regex]::Escape('Convert.ToInt32(impersonatorTenantIdClaim.Value)'), 'impersonatorTenantIdClaim.Value'
    $content = $content -creplace [Regex]::Escape('int? GetImpersonatorTenantId'), 'string GetImpersonatorTenantId'

    $content = $content -creplace [Regex]::Escape('long? ImpersonatorUserId'), 'string ImpersonatorUserId'
    $content = $content -creplace [Regex]::Escape('long ImpersonatorUserId'), 'string ImpersonatorUserId'
    $content = $content -creplace [Regex]::Escape('long? impersonatorUserId'), 'string impersonatorUserId'
    $content = $content -creplace [Regex]::Escape('long impersonatorUserId'), 'string impersonatorUserId'
    $content = $content -creplace [Regex]::Escape('Convert.ToInt64(impersonatorUserIdClaim.Value)'), 'impersonatorUserIdClaim.Value'
    $content = $content -creplace [Regex]::Escape('long? GetImpersonatorUserId'), 'string GetImpersonatorUserId'
    
    $content = $content -creplace [Regex]::Escape('TenantId.ToString()'), 'TenantId'
    $content = $content -creplace [Regex]::Escape('UserId.ToString()'), 'UserId'
    $content = $content -creplace [Regex]::Escape('ImpersonatorTenantId.ToString()'), 'ImpersonatorTenantId'
    $content = $content -creplace [Regex]::Escape('ImpersonatorUserId.ToString()'), 'ImpersonatorUserId'
    $content = $content -creplace [Regex]::Escape('int? GetCurrentTenantId()'), 'string GetCurrentTenantId()'
    $content = $content -creplace [Regex]::Escape('GetCurrentTenantId() ?? 0'), 'GetCurrentTenantId() ?? "0"'

    ## InMemoryBackgroundJobStore
    $content = $content -creplace [Regex]::Escape('ConcurrentDictionary<long, BackgroundJobInfo>'), 'ConcurrentDictionary<string, BackgroundJobInfo>'
    $content = $content -creplace [Regex]::Escape('Interlocked.Increment(ref _lastId);'), 'Interlocked.Increment(ref _lastId).ToString();'
    $content = $content -creplace [Regex]::Escape('long jobId'), 'string jobId'
    $content = $content -creplace [Regex]::Escape('GetAsync(finalJobId)'), 'GetAsync(jobId)'
    $content = $content -creplace [Regex]::Escape('Get(finalJobId)'), 'Get(jobId)'

    ## UserIdentifier
    $content = $content -creplace [Regex]::Escape('splitted[0].To<long>()'), 'splitted[0]'
    $content = $content -creplace [Regex]::Escape('splitted[1].To<int>()'), 'splitted[1]'

    ## Others
    $content = $content -creplace [Regex]::Escape('Find(string tenantId)'), 'FindById(string tenantId)'
    $content = $content -creplace [Regex]::Escape('long? GetAuditUserId'), 'string GetAuditUserId'
    $content = $content -creplace [Regex]::Escape('long? GetImpersonatorTenantId'), 'string GetImpersonatorTenantId'
    $content = $content -creplace [Regex]::Escape('int? GetCurrentTenantId'), 'string GetCurrentTenantId'
    $content = $content -creplace [Regex]::Escape('int GetCurrentTenantId'), 'string GetCurrentTenantId'
    $content = $content -creplace [Regex]::Escape('int? GetTenantId'), 'string GetTenantId'
    $content = $content -creplace [Regex]::Escape('int GetTenantId'), 'string GetTenantId'
    $content = $content -creplace [Regex]::Escape('int[] AllTenants'), 'string[] AllTenants'
    $content = $content -creplace [Regex]::Escape('Controller<TEntity, int>'), 'Controller<TEntity, string>'
    $content = $content -creplace [Regex]::Escape('(int)filter.FilterParameters[AbpDataFilters.Parameters.TenantId]'), '(string)filter.FilterParameters[AbpDataFilters.Parameters.TenantId]'
    $content = $content -creplace [Regex]::Escape('(int?)filter.FilterParameters[AbpDataFilters.Parameters.TenantId]'), '(string)filter.FilterParameters[AbpDataFilters.Parameters.TenantId]'
    $content = $content -creplace 'TenantInfo\(([0-9].*?), "(.*?)"\)', 'TenantInfo("$1", "$2")'

    # enantStore\.Find\(.*?[i|I]d
    #
    $content = $content -creplace [Regex]::Escape('tenant == null ? null : (int?) tenant.Id'), 'tenant == null ? null : tenant.Id'
    $content = $content -creplace [Regex]::Escape('tenant == null ? (int?)null : (int?)tenant.Id'), 'tenant == null ? null : tenant.Id'
    $content = $content -creplace [Regex]::Escape('long GetUserId'), 'string GetUserId'
    $content = $content -creplace [Regex]::Escape('int, Dictionary<string, SettingInfo>'), 'string, Dictionary<string, SettingInfo>'
    $content = $content -creplace [Regex]::Escape('long, Dictionary<string, SettingInfo>'), 'long, Dictionary<string, SettingInfo>'
    $content = $content -creplace [Regex]::Escape('value != 1'), 'value != "1"'
    $content = $content -creplace [Regex]::Escape('return 1;'), 'return "1";'
    $content = $content -creplace [Regex]::Escape('entity.TenantId != 0'), 'entity.TenantId != "0"'
    $content = $content -creplace [Regex]::Escape('(int?) t.TenantId == null'), '!t.TenantId.HasValue()'
    $content = $content -creplace [Regex]::Escape('AbpSession.TenantId ?? 0'), 'AbpSession.TenantId ?? "0"'
    $content = $content -creplace [Regex]::Escape('  0);'), '  "0");'
    $content = $content -creplace [Regex]::Escape('Cache<int, TenantCacheItem>'), 'Cache<string, TenantCacheItem>'
    $content = $content -creplace [Regex]::Escape('Cache<string, int?>'), 'Cache<string, string>'
    $content = $content -creplace [Regex]::Escape('Cache<int, TenantFeatureCacheItem>'), 'Cache<string, TenantFeatureCacheItem>'
    $content = $content -creplace [Regex]::Escape('Cache<int, EditionfeatureCacheItem>'), 'Cache<string, EditionfeatureCacheItem>'
    $content = $content -creplace [Regex]::Escape('Cache<int, Dictionary<string, ApplicationLanguage>>'), 'Cache<string, Dictionary<string, ApplicationLanguage>>'
    

    $content = $content -creplace [Regex]::Escape('int? EditionId'), 'string EditionId'
    $content = $content -creplace [Regex]::Escape('int EditionId'), 'string EditionId'
    $content = $content -creplace [Regex]::Escape('int? editionId'), 'string editionId'
    $content = $content -creplace [Regex]::Escape('int editionId'), 'string editionId'

    
    ## dynamic entitys
    if ([regex]::IsMatch($content, 'namespace Abp.DynamicEntityProperties')) {
        $content = $content -creplace [Regex]::Escape('Cache<int, DynamicEntityProperty>'), 'Cache<string, DynamicEntityProperty>'
        $content = $content -creplace [Regex]::Escape('Cache<int, DynamicProperty>'), 'Cache<string, DynamicProperty>'
        $content = $content -creplace [Regex]::Escape('int? id'), 'string id'
        $content = $content -creplace [Regex]::Escape('int id'), 'string id'
        $content = $content -creplace [Regex]::Escape('long? id'), 'string id'
        $content = $content -creplace [Regex]::Escape('long id'), 'string id'
        # DynamicEntityPropertyValueManagerExtensions.cs
        $content = $content -creplace [Regex]::Escape('<TEntity, int>'), '<TEntity, string>'
        $content = $content -creplace [Regex]::Escape('int dynamicPropertyId'), 'string dynamicPropertyId'
        $content = $content -creplace [Regex]::Escape('int DynamicPropertyId'), 'string DynamicPropertyId'
        $content = $content -creplace [Regex]::Escape('int dynamicEntityPropertyId'), 'string dynamicEntityPropertyId'
        $content = $content -creplace [Regex]::Escape('int DynamicEntityPropertyId'), 'string DynamicEntityPropertyId'
        $content = $content -creplace [Regex]::Escape('int GetDynamicPropertyId'), 'string GetDynamicPropertyId'
        $content = $content -creplace [Regex]::Escape('Task<int> GetDynamicPropertyIdAsync'), 'Task<string> GetDynamicPropertyIdAsync'
    }
    
    ## EntitySnapshotManagerExtensions.cs
    if ($path.EndsWith('EntitySnapshotManagerExtensions.cs')) {
        $content = $content -creplace [Regex]::Escape('int id, '), 'string id, '
        $content = $content -creplace [Regex]::Escape('<TEntity, int>'), '<TEntity, string>'
    }
    ## TenantInfo.cs
    if ([regex]::IsMatch($content, 'class TenantInfo')) {
        $content = $content -creplace [Regex]::Escape('int Id'), 'string Id'
        $content = $content -creplace [Regex]::Escape('int id'), 'string id'
    }
    ## TenantCacheItem.cs
    if ($path.EndsWith('TenantCacheItem.cs')) {
        $content = $content -creplace [Regex]::Escape('int Id'), 'string Id'
    }
    ## OrganizationUnitManager.cs
    if ($path.EndsWith('OrganizationUnitManager.cs') -or $path.EndsWith('AbpEditionManager.cs') -or $path.EndsWith('AbpTenantManager.cs')) {
        $content = $content -creplace [Regex]::Escape('long Id'), 'string Id'
        $content = $content -creplace [Regex]::Escape('long id'), 'string id'
        $content = $content -creplace [Regex]::Escape('int Id'), 'string Id'
        $content = $content -creplace [Regex]::Escape('int id'), 'string id'
    }
    ## TestAbpSession
    if ($path.EndsWith('TestAbpSession.cs')) {
        $content = $content -creplace [Regex]::Escape('if (resolvedValue != null)'), 'if (resolvedValue.HasValue())'
    }
    ## MemoryRepositoryOfTEntity
    if ($path.EndsWith('MemoryRepositoryOfTEntity.cs')) {
        $content = $content -creplace [Regex]::Escape('string'), 'int'
        $content = $content -creplace [Regex]::Escape('IRepository<TEntity>'), 'IRepository<TEntity,int>'
    }

    ### ITenantCache
    if ($path.EndsWith('TenantCache.cs')) {
        $content = $content -creplace [Regex]::Escape('(string tenantId)'), '(string tenantId,int? fsTagNone=null)'
        $content = $content -creplace [Regex]::Escape('(tenantId)'), '(tenantId,null)'
        $content = $content -creplace '(FirstOrDefault.*?tenantId).*?\)', '$1)'
    }
    ### DynamicPropertyStore
    if ($path.EndsWith('DynamicPropertyStore.cs')) {
        $content = $content -creplace ' (Get.*?id)\)', ' $1,int? fsTagNone=null)'
    }
    ### DynamicPropertyManager
    if ($path.EndsWith('DynamicPropertyManager.cs')) {
        $content = $content -creplace ' (Get.*?id)\)', ' $1,int? fsTagNone=null)'
    }
    ### DynamicEntityPropertyValueStore
    if ($path.EndsWith('DynamicEntityPropertyValueStore.cs')) {
        $content = $content -creplace ' (GetValues.*?entityFullName.*?entityId)\)', ' $1,int? fsTagNone=null)'
    }
    ### DynamicEntityPropertyValueManager
    if ($path.EndsWith('DynamicEntityPropertyValueManager.cs')) {
        $content = $content -creplace ' (GetValues.*?entityFullName.*?entityId)\)', ' $1,int? fsTagNone=null)'
        $content = $content -creplace ' (GetValues.*?entityFullName.*?propertyName)\)', ' $1,int? fsTagNone=null)'
        $content = $content -creplace '(    string propertyName)\)', ' $1,int? fsTagNone=null)'
    }
    ### AbpDbContext.cs
    if ($path.EndsWith('AbpDbContext.cs')) {
        $content = $content -creplace [Regex]::Escape('t.TenantId == tenantId || !t.TenantId.HasValue()'), 't.TenantId == tenantId || t.TenantId==null || t.TenantId==""'
        $content = $content -creplace [Regex]::Escape('t.TenantId == tenantId, 0'), 't.TenantId == tenantId, "0"'
    }
    ### HubCallerContextExtensions.cs
    if ($path.EndsWith('HubCallerContextExtensions.cs') -or $path.EndsWith('ClaimsAbpSession.cs')) {
        $content = $content -creplace [Regex]::Escape('if (!long.TryParse(userIdClaim.Value, out var userId))'), 'return userIdClaim?.Value??string.Empty; var userId = string.Empty;'
        $content = $content -creplace [Regex]::Escape('if (!long.TryParse(userIdClaim.Value, out userId))'), 'return userIdClaim?.Value??string.Empty;'
    }
    ### AbpRoleManager.cs
    if ($path.EndsWith('AbpRoleManager.cs')) {
        $content = $content -creplace [Regex]::Escape('IsGrantedAsync(string roleId, string permissionName)'), 'IsGrantedAsync(string roleId, string permissionName, int? fsTagNone=null)'
        $content = $content -creplace [Regex]::Escape('GetGrantedPermissionsAsync(string roleId)'), 'GetGrantedPermissionsAsync(string roleId, int? fsTagNone=null)'
    }
    ### DynamicEntityPropertyValueManagerExtensions.cs
    if ($path.EndsWith('DynamicEntityPropertyValueManagerExtensions.cs')) {
        $content = $content -creplace [Regex]::Escape('GetValues<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName)'), 'GetValues<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)'
        $content = $content -creplace [Regex]::Escape('GetValuesAsync<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName)'), 'GetValuesAsync<TEntity>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)'
        $content = $content -creplace [Regex]::Escape('GetValues<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName)'), 'GetValues<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)'
        $content = $content -creplace [Regex]::Escape('GetValuesAsync<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName)'), 'GetValuesAsync<TEntity, TPrimaryKey>(this IDynamicEntityPropertyValueManager manager, string entityId, string propertyName, int? fsTagNone=null)'
        
    }

    if ($path.EndsWith('SettingManager.cs') -or $path.EndsWith('TenantResolver.cs')) {
        $content = $content -creplace [Regex]::Escape('tenantStore.Find(tenantId)'), 'tenantStore.FindById(tenantId)'
    }

    if ($path.EndsWith('EfGenericRepositoryRegistrar.cs') -or $path.EndsWith('SecondaryOrmRegistrarBase.cs')) {
        $content = $content -creplace [Regex]::Escape('if (primaryKeyType == typeof(int))'), 'if (primaryKeyType == typeof(string))'
    }

    if ($path.EndsWith('CreationAuditDapperActionFilter.cs') -or $path.EndsWith('AbpDbContext.cs')) {
        $content = $content -creplace [Regex]::Escape('if (entity.TenantId != "0")'), 'if (entity.TenantId.HasValue())'
        $content = $content -creplace [Regex]::Escape('if (currentTenantId != null)'), 'if (currentTenantId.HasValue())'
        $content = $content -creplace [Regex]::Escape('if (entity.TenantId != null)'), 'if (entity.TenantId.HasValue())'
    }
    if ($path.EndsWith('TenantStore.cs') -or $path.EndsWith('DbPerTenantConnectionStringResolver.cs')) {
        $content = $content -creplace [Regex]::Escape('tenantCache.GetOrNullAsync(tenantId)'), 'tenantCache.GetOrNullAsync(tenantId, null)'
        $content = $content -creplace [Regex]::Escape('tenantCache.GetOrNull(tenantId)'), 'tenantCache.GetOrNull(tenantId, null)'
        $content = $content -creplace [Regex]::Escape('tenantCache.Get(args.TenantId)'), 'tenantCache.Get(args.TenantId,null)'
        $content = $content -creplace [Regex]::Escape('tenantCache.GetAsync(args.TenantId)'), 'tenantCache.GetAsync(args.TenantId,null)'
    }
    # $content = $content -creplace [Regex]::Escape('Get(string tenantId)'), 'GetById(string tenantId)'
    # $content = $content -creplace [Regex]::Escape('GetAsync(string tenantId)'), 'GetByIdAsync(string tenantId)'
    # $content = $content -creplace [Regex]::Escape('GetOrNull(string tenantId)'), 'GetOrNullById(string tenantId)'
    # $content = $content -creplace [Regex]::Escape('GetOrNullAsync(string tenantId)'), 'GetOrNullByIdAsync(string tenantId)'
    # $content = $content -creplace [Regex]::Escape('GetTenantOrNull(string tenantId)'), 'GetTenantOrNullById(string tenantId)'
    # $content = $content -creplace [Regex]::Escape('GetTenantOrNullAsync(string tenantId)'), 'GetTenantOrNullByIdAsync(string tenantId)'

    # $content = $content -creplace 'Get(tenantId)', 'GetById(tenantId)'
    # $content = $content -creplace 'GetAsync\(tenantId\)', 'GetByIdAsync(tenantId)'
    # $content = $content -creplace 'GetOrNull\(tenantId\)', 'GetOrNullById(tenantId)'
    # $content = $content -creplace 'GetOrNullAsync\(tenantId\)', 'GetOrNullByIdAsync(tenantId)'
    # $content = $content -creplace 'GetTenantOrNull\(tenantId\)', 'GetTenantOrNullById(tenantId)'
    # $content = $content -creplace 'GetTenantOrNullAsync\(tenantId\)', 'GetTenantOrNullByIdAsync(tenantId)'



    $content = $content -creplace [Regex]::Escape('ParentId.HasValue'), 'ParentId.HasValue()'
    $content = $content -creplace [Regex]::Escape('parentId.HasValue'), 'parentId.HasValue()'
    $content = $content -creplace [Regex]::Escape('ParentId.Value'), 'ParentId'
    $content = $content -creplace [Regex]::Escape('parentId.Value'), 'parentId'
    $content = $content -creplace [Regex]::Escape('long? parentId'), 'string parentId'
    $content = $content -creplace [Regex]::Escape('long? ParentId'), 'string ParentId'
    $content = $content -creplace [Regex]::Escape('int RoleId'), 'string RoleId'


    # 写入内容到文件
    $content = $content -creplace [Regex]::Escape('.HasValue()()'), '.HasValue()'
    $content = $content -creplace [Regex]::Escape('t.TenantId==""()'), 't.TenantId==""'
    WriteFile -Path $path  -Content $content
}


# 替换测试的
function ReplaceTests {
    param (
        [string]$path
    )

    # 读取文件内容
    $content = ReadFile -Path $path
     

    $content = $content -creplace 'Id = ([0-9].*?),', 'Id = "$1",'
    $content = $content -creplace 'Id = ([0-9].*?);', 'Id = "$1";'
    $content = $content -creplace 'Id = ([0-9].*?) ', 'Id = "$1" '    
    $content = $content -creplace 'Id = ([0-9].*?);', 'Id = "$1";'    
    $content = $content -creplace 'id = ([0-9].*?);', 'id = "$1";'    
    $content = $content -creplace 'tenantId = ([0-9].*?[0-9])', 'tenantId = "$1"'    
    $content = $content -creplace 'AbpSession.Use\(([0-9].*?), ([0-9].*?)\)', 'AbpSession.Use("$1","$2")'    
    $content = $content -creplace [Regex]::Escape('Dictionary<string, int> connections = new Dictionary<string, int>()'), 'Dictionary<string, string> connections = new Dictionary<string, string>()'
    $content = $content -creplace [Regex]::Escape('MakeNewConnectionId(), i + 1)'), 'MakeNewConnectionId(), (i + 1).ToString())'
    $content = $content -creplace [Regex]::Escape('tenantIds: new int?[]'), 'tenantIds: new string[]'
    $content = $content -creplace [Regex]::Escape('TenantId.Returns((int?) null)'), 'TenantId.Returns((string)null)'
    $content = $content -creplace [Regex]::Escape('UserId.Returns((int?) null)'), 'UserId.Returns((string)null)'
    $content = $content -creplace 'TenantId.Returns\(([0-9].*?)\)', 'TenantId.Returns("$1")'
    $content = $content -creplace 'UserId.Returns\(([0-9].*?)\)', 'UserId.Returns("$1")'
    $content = $content -creplace 'TenantId.ShouldBe\(([0-9].*?)\)', 'TenantId.ShouldBe("$1")'
    $content = $content -creplace 'UserId.ShouldBe\(([0-9].*?)\)', 'UserId.ShouldBe("$1")'
    $content = $content -creplace 'TenantId = ([0-9].*?[0-9])', 'TenantId = "$1"'
    $content = $content -creplace 'TenantId = ([0-9].*?);', 'TenantId = "$1";'
    $content = $content -creplace 'TenantId == ([0-9].*?)\)', 'TenantId == "$1")'
    $content = $content -creplace 'TenantId != ([0-9].*?)\)', 'TenantId != "$1")'
    $content = $content -creplace 'UserId = ([0-9].*?);', 'UserId = "$1";'
    $content = $content -creplace 'GetAllSettingValuesForTenantAsync\(([0-9].*?)\)', 'GetAllSettingValuesForTenantAsync("$1")'
    $content = $content -creplace 'UserIdentifier\(([0-9].*?), ([0-9].*?)\)', 'UserIdentifier("$1","$2")'
    $content = $content -creplace 'eventData.Entity.Id.ShouldBe\(([0-9].*?)\)', 'eventData.Entity.Id.ShouldBe("$1")'
    $content = $content -creplace 'SettingInfo\(([0-9].*?), ([0-9].*?)', 'SettingInfo("$1", "$2"'
    $content = $content -creplace 'SettingInfo\(([0-9].*?), null', 'SettingInfo("$1", null'
    $content = $content -creplace 'GetSettingOrNullAsync\(([0-9].*?), ([0-9].*?)', 'GetSettingOrNullAsync("$1", "$2"'    
    $content = $content -creplace 'GetSettingOrNullAsync\(([0-9].*?), null', 'GetSettingOrNullAsync("$1", null'
    $content = $content -creplace '_store.GetAsync\(([0-9].*?)\)', '_store.GetAsync("$1")'
    $content = $content -creplace 'ChangeSettingForUserAsync\(([0-9].*?),', 'ChangeSettingForUserAsync("$1",'
    $content = $content -creplace 'ChangeSettingForTenantAsync\(([0-9].*?),', 'ChangeSettingForTenantAsync("$1",'
    $content = $content -creplace 'OnlineClient\(connectionId, "127.0.0.1", ([0-9].*?), ([0-9].*?)\)', 'OnlineClient(connectionId, "127.0.0.1", "$1", "$2")'
    $content = $content -creplace '\[InlineData\("(.*?)", "(.*?)", ([0-9].*?)\)\]', '[InlineData("$1", "$2", "$3")]'
    $content = $content -creplace [Regex]::Escape('GetPrimaryKeyType<Manager>().ShouldBe(typeof(int))'), 'GetPrimaryKeyType<Manager>().ShouldBe(typeof(string))'
    $content = $content -creplace [Regex]::Escape('GetPrimaryKeyType(typeof(Manager)).ShouldBe(typeof(int))'), 'GetPrimaryKeyType(typeof(Manager)).ShouldBe(typeof(string))'
    $content = $content -creplace [Regex]::Escape('if (resolvedValue != null)'), 'if (resolvedValue.HasValue())'
    $content = $content -creplace [Regex]::Escape('var response = await GetResponseAsObjectAsync<AjaxResponse<int?>>('), 'var response = await GetResponseAsObjectAsync<AjaxResponse<string>>('
    $content = $content -creplace [Regex]::Escape('Result.ShouldBe(42)'), 'Result.ShouldBe("42")'
    $content = $content -creplace 'SetTenantId\(([0-9].*?)\)', 'SetTenantId("$1")'
    $content = $content -creplace [Regex]::Escape('.ShouldBe(1); //Not sure about that?,Because we changed TenantId to 2'), '.ShouldBe("1"); //Not sure about that?,Because we changed TenantId to 2'

   
    ## Abp.AutoMapper.Tests
    if ($path.EndsWith('AutoMapper_Inheritance_Tests.cs') -or $path.EndsWith('AutoMapping_Tests.cs') -or $path.EndsWith('StaticAutoMapper_Tests.cs')) {
        $content = $content -creplace [Regex]::Escape('int Id'), 'string Id'
        $content = $content -creplace [Regex]::Escape('int SecondId'), 'string SecondId'
        $content = $content -creplace [Regex]::Escape('int ThirdId'), 'string ThirdId'
        $content = $content -creplace 'Id.ShouldBe\(([0-9].*?)\)', 'Id.ShouldBe("$1")'
    }

    ## Abp.Dapper.Tests
    if ([regex]::IsMatch($path, [Regex]::Escape('Abp.Dapper.Tests'))) {
        $content = $content -creplace [Regex]::Escape('DeleterUserId BIGINT'), 'DeleterUserId NVARCHAR(1024)'
        $content = $content -creplace [Regex]::Escape('CreatorUserId BIGINT'), 'CreatorUserId NVARCHAR(1024)'
        $content = $content -creplace [Regex]::Escape('LastModifierUserId BIGINT'), 'LastModifierUserId NVARCHAR(1024)'
        $content = $content -creplace [Regex]::Escape('TenantId INTEGER NULLABLE'), 'TenantId INTEGER'
        $content = $content -creplace [Regex]::Escape('TenantId INTEGER'), 'TenantId NVARCHAR(1024)'

        # $content = $content -creplace [Regex]::Escape('.InsertAndGetIdAsync(new ProductDetail("Woman"));'), '.InsertAndGetIdAsync(new ProductDetail("Woman"));await _unitOfWorkManager.Current.SaveChangesAsync();'
        # $content = $content -creplace [Regex]::Escape('Map(x => x.Id)'), '// Map(x => x.Id)'
        # $content = $content -creplace [Regex]::Escape('new Good {Name = "AbpTest"}'), 'new Good { Id="1", Name = "AbpTest"}'


        $content = $content -creplace '(class Good.*?Entity).*', '$1<int>'
        $content = $content -creplace [Regex]::Escape('Repository<Good>'), 'Repository<Good,int>'

        $content = $content -creplace '(class Person.*?Entity).*?,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<Person>'), 'Repository<Person,int>'

        $content = $content -creplace '(class Product.*?Entity).*?,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<Product>'), 'Repository<Product,int>'
        $content = $content -creplace [Regex]::Escape('Repository<ProductDetail>'), 'Repository<ProductDetail,int>'
        $content = $content -creplace [Regex]::Escape('int? id = "1";'), 'int? id = 1;'

        # $content = $content -creplace [Regex]::Escape('int productWithTenant2Id'), 'string productWithTenant2Id'
        # $content = $content -creplace 'int (productWithTenant.*?Id)', 'string $1'
        # $content = $content -creplace 'int (personWithTenantId.*)=', 'string $1='
        # $content = $content -creplace [Regex]::Escape('int? id = 1;'), 'string id = "1";'
    }

    ## Abp.EntityFramework.Tests
    if ([regex]::IsMatch($path, [Regex]::Escape('Abp.EntityFramework.Tests'))) {
        $content = $content -creplace [Regex]::Escape('MyEntity1, int'), 'MyEntity1, string'
        $content = $content -creplace '(class MyEntity2.*?Entity).*', '$1<long>'
    }

    ## Abp.EntityFrameworkCore.Dapper.Tests
    # if ([regex]::IsMatch($path, [Regex]::Escape('Abp.EntityFrameworkCore.Dapper.Tests'))) {
    #     $content = $content -creplace '(class Comment.*?Entity).*', '$1<long>'
    #     $content = $content -creplace '(class Blog.*?AggregateRoot),', '$1<int>,'
    #     $content = $content -creplace [Regex]::Escape('Repository<Blog>'), 'Repository<Blog,int>'
    #     $content = $content -creplace 'blogId = \"(.*?)\"', 'blogId = $1'
    # }

    ## Abp.EntityFrameworkCore.Tests
    if ([regex]::IsMatch($path, [Regex]::Escape('Abp.EntityFrameworkCore.Tests')) -or [regex]::IsMatch($path, [Regex]::Escape('Abp.EntityFrameworkCore.Dapper.Tests'))) {

        # $content = $content -creplace '(class Comment.*?Entity).*', '$1<long>'
        # $content = $content -creplace '(class Blog.*?AggregateRoot),', '$1<int>,'
        # $content = $content -creplace [Regex]::Escape('Repository<Blog>'), 'Repository<Blog,int>'
        # $content = $content -creplace 'blogId = \"(.*?)\"', 'blogId = $1'

        
        $content = $content -creplace '(class TicketListItem.*?)IEntity.*', '$1IEntity<int>'
        $content = $content -creplace [Regex]::Escape('Repository<TicketListItem>'), 'Repository<TicketListItem,int>'
        $content = $content -creplace [Regex]::Escape('RepositoryBase<TicketListItem>'), 'RepositoryBase<TicketListItem,int>'


        $content = $content -creplace '(class Ticket.*?Entity).*?,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<Ticket>'), 'Repository<Ticket,int>'

        if ([regex]::IsMatch($path, [Regex]::Escape('Abp.EntityFrameworkCore.Tests'))) {
            $content = $content -creplace '(class Comment.*?Entity).*', '$1<int>'
            $content = $content -creplace [Regex]::Escape('Repository<Comment>'), 'Repository<Comment,int>'
        }
        elseif ([regex]::IsMatch($path, [Regex]::Escape('Abp.EntityFrameworkCore.Dapper.Tests'))) {
            $content = $content -creplace '(class Comment.*?Entity).*', '$1<long>'
            $content = $content -creplace [Regex]::Escape('var blogId = "0";'), 'var blogId = 0;'
        }
        

        $content = $content -creplace '(class BlogView.*?Entity).*', '$1<int>'
        $content = $content -creplace [Regex]::Escape('Repository<BlogView>'), 'Repository<BlogView,int>'

        $content = $content -creplace '(class Blog.*?AggregateRoot).*,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<Blog>'), 'Repository<Blog,int>'

        $content = $content -creplace '(class BlogCategory.*?AggregateRoot).*,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<BlogCategory>'), 'Repository<BlogCategory,int>'

        $content = $content -creplace '(class SubBlogCategory.*?Entity).*,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<SubBlogCategory>'), 'Repository<SubBlogCategory,int>'
    }
    ## Abp.MemoryDb.Tests
    if ([regex]::IsMatch($path, [Regex]::Escape('Abp.MemoryDb.Tests'))) {
        $content = $content -creplace '(class MyEntity : Entity).*', '$1<int>'
        $content = $content -creplace [Regex]::Escape('IRepository<MyEntity>'), 'IRepository<MyEntity,int>'
    }
    ## Abp.ZeroCore.SampleApp
    ## Abp.ZeroCore.Tests
    if ([regex]::IsMatch($path, [Regex]::Escape('Abp.ZeroCore.Tests')) -or [regex]::IsMatch($path, [Regex]::Escape('Abp.ZeroCore.SampleApp'))) {
        $content = $content -creplace '(AsyncCrudAppService.*?)long', '$1string'
        $content = $content -creplace '(AsyncCrudAppService.*?)int', '$1string'
        $content = $content -creplace 'User, long', 'User, string'
        $content = $content -creplace [Regex]::Escape('defaultEdition.Id > 0'), 'defaultEdition.Id.HasValue()'
        $content = $content -creplace [Regex]::Escape('int _tenantId'), 'string _tenantId'
        $content = $content -creplace [Regex]::Escape('_tenantId != 1'), '_tenantId != "1"'
        $content = $content -creplace [Regex]::Escape('TenantRoleAndUserBuilder(context, 1)'), 'TenantRoleAndUserBuilder(context, "1")'

        
        $content = $content -creplace '(class Product.*?Entity).*?,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<Product>'), 'Repository<Product, int>'
        $content = $content -creplace [Regex]::Escape('Repository<ProductTranslation>'), 'Repository<ProductTranslation, int>'

        $content = $content -creplace '(class Order.*?Entity).*?,', '$1<int>,'

        $content = $content -creplace [Regex]::Escape('Repository<Order>'), 'Repository<Order, int>'

        $content = $content -creplace '(class Advertisement.*?Entity).*', '$1<int>'
        $content = $content -creplace [Regex]::Escape('Repository<Advertisement>'), 'Repository<Advertisement, int>'

        $content = $content -creplace '(class Product.*?EntityDto).*', '$1<int>'
        $content = $content -creplace '(class Order.*?EntityDto).*', '$1<int>'

        $content = $content -creplace [Regex]::Escape('CreateMultiLingualMap<Product, ProductTranslation'), 'CreateMultiLingualMap<Product,int, ProductTranslation'
        $content = $content -creplace [Regex]::Escape('CreateMultiLingualMap<Order, OrderTranslation'), 'CreateMultiLingualMap<Order,int, OrderTranslation'

        $content = $content -creplace '(class UserTestEntity.*?AggregateRoot).*?,', '$1<int>,'

        $content = $content -creplace [Regex]::Escape('Repository<TenantFeatureSetting, long'), 'Repository<TenantFeatureSetting, string'
        $content = $content -creplace [Regex]::Escape('Repository<Product>'), 'Repository<Product, int>'
        $content = $content -creplace [Regex]::Escape('Repository<UserTestEntity>'), 'Repository<UserTestEntity, int>'
        $content = $content -creplace [Regex]::Escape('Repository<Advertisement>'), 'Repository<Advertisement, int>'
        $content = $content -creplace [Regex]::Escape('new TestDataBuilder(context, 1)'), 'new TestDataBuilder(context, "1")'
        $content = $content -creplace [Regex]::Escape('r.Id > 0'), 'r.Id !=null && r.Id != string.Empty'
        $content = $content -creplace [Regex]::Escape('u.Id > 0'), 'u.Id !=null && u.Id != string.Empty'
        $content = $content -creplace [Regex]::Escape('int _tenantId'), 'string _tenantId'
        $content = $content -creplace [Regex]::Escape('InitializeOptionsAsync(1)'), 'InitializeOptionsAsync("1")'
        $content = $content -creplace [Regex]::Escape('GetSnapshotAsync<UserTestEntity>'), 'GetSnapshotAsync<UserTestEntity,int>'
        $content = $content -creplace [Regex]::Escape('string userId;'), 'int userId;'
        $content = $content -creplace [Regex]::Escape('Convert.ToInt64(id).ShouldBeGreaterThan(0);'), 'id.ShouldNotBeNullOrWhiteSpace();'
        $content = $content -creplace [Regex]::Escape('entityChange.EntityEntry.As<EntityEntry>().Entity.As<IEntity<string>>().Id'), 'entityChange.EntityEntry.As<EntityEntry>().Entity.As<IEntity<int>>().Id'
        $content = $content -creplace [Regex]::Escape('entityChangeBlog.EntityEntry.As<EntityEntry>().Entity.As<IEntity<string>>()'), 'entityChangeBlog.EntityEntry.As<EntityEntry>().Entity.As<IEntity<int>>()'


        $content = $content -creplace '(blog.*?Id).*?=.*?"(.*?)"', '$1 = $2'
        $content = $content -creplace '(class Blog.*?AggregateRoot).*,', '$1<int>,'
        $content = $content -creplace [Regex]::Escape('Repository<Blog>'), 'Repository<Blog,int>'

        $content = $content -creplace '(class Comment.*?Entity).*', '$1<int>'
        $content = $content -creplace [Regex]::Escape('Repository<Comment>'), 'Repository<Comment,int>'
        $content = $content -creplace [Regex]::Escape('Id = "42",'), 'Id = 42,'
        $content = $content -creplace '(_roleManager\.IsGrantedAsync\(adminRole.Id,.*?)\)', '$1,null)'
        $content = $content -creplace '(_roleManager\.IsGrantedAsync\(adminRole.Id,.*?),.*?\)', '$1,null)'

        ## SimpleEntityHistory_Test.cs
        if ($path.EndsWith('SimpleEntityHistory_Test.cs')) {
            $content = $content -creplace [Regex]::Escape('EntityEntry.As<EntityEntry>().Entity.As<IEntity>'), 'EntityEntry.As<EntityEntry>().Entity.As<IEntity<int>>'
        }
    }
    if (
        [regex]::IsMatch($path, [Regex]::Escape('GenericInheritanceTest.cs'))
    ) {
        # $content = $content -creplace [Regex]::Escape('class Person : Entity'), 'class Person : Entity<int>'
    }

    ## EntityDtoSerialization_Tests.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('EntityDtoSerialization_Tests.cs'))
    ) {
        $content = $content -creplace [Regex]::Escape('Id = 42'), 'Id = "42"'
    }

    ## JsonSerializationHelper_Tests.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('JsonSerializationHelper_Tests.cs'))
    ) {
        $content = $content -creplace [Regex]::Escape('"Abp.Localization.LocalizableString, Abp,'), '"Abp.Localization.LocalizableString, Yoyo.Abp,'
    }
    ## DefaultTenantBuilder.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('DefaultTenantBuilder.cs'))
    ) {
        $content = $content -creplace [Regex]::Escape('new Tenant(Tenant.DefaultTenantName, Tenant.DefaultTenantName);'), 'new Tenant(Tenant.DefaultTenantName, Tenant.DefaultTenantName) { Id="1"};'
    }

    ## ApplicationWithoutDb_Tests.cs Validation_Tests.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('ApplicationWithoutDb_Tests.cs')) -or [regex]::IsMatch($path, [Regex]::Escape('Validation_Tests.cs'))
    ) {
        $content = $content -creplace [Regex]::Escape('Result.ShouldBe("42")'), 'Result.ShouldBe(42)'
        $content = $content -creplace [Regex]::Escape('string Value { get; set; }'), 'int Value { get; set; }'
        $content = $content -creplace [Regex]::Escape('{ Value = "42" }'), '{ Value = 42 }'
    }

    $content = $content -creplace '(TenantId) = ([0-9].*?[0-9])', '$1 = "$2"'
    $content = $content -creplace [Regex]::Escape(' }"'), '"}'
    $content = $content -creplace [Regex]::Escape('(0")'), '(0)'
    $content = $content -creplace [Regex]::Escape('(1")'), '(0)'
    $content = $content -creplace [Regex]::Escape('"}, Encoding.UTF8,'), '}", Encoding.UTF8,'
    $content = $content -creplace [Regex]::Escape(' }))";'), '" }));'
    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}

## 替换测试中的demo
function ReplaceTestDemos {
    param (
        [string]$path
    )

    if (![regex]::IsMatch($path, [Regex]::Escape('aspnet-core-demo'))) {
        return;
    }

    # 读取文件内容
    $content = ReadFile -Path $path

    ## ApplicationWithoutDb_Tests.cs Validation_Tests.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('MyDbContext.cs')) -or [regex]::IsMatch($path, [Regex]::Escape('ProductAppService.cs')) -or [regex]::IsMatch($path, [Regex]::Escape('TestAppService.cs'))
    ) {
        $content = $content -creplace [Regex]::Escape('int CreateProduct('), 'string CreateProduct('
        $content = $content -creplace [Regex]::Escape('Id = 1'), 'Id = "1"'
        $content = $content -creplace [Regex]::Escape('Id = 42,'), 'Id = "42",'
    }

    # ## AbpAspNetCoreDemo.Core
    # if (
    #     [regex]::IsMatch($path, [Regex]::Escape('AbpAspNetCoreDemo.Core')) -and [regex]::IsMatch($path, [Regex]::Escape('Product.cs'))
    # ) {
    #     $content = $content -creplace '(class Product.*?Entity).*?', '$1<long>'
    # }

    # ## AbpAspNetCoreDemo
    # if (
    #     [regex]::IsMatch($path, [Regex]::Escape('AbpAspNetCoreDemo'))
    # ) {
    #     $content = $content -creplace [Regex]::Escape('= "42"'), '= 42'
    #     $content = $content -creplace [Regex]::Escape('= "1"'), '= 1'
    #     $content = $content -creplace [Regex]::Escape('string CreateProduct('), 'long CreateProduct('
    #     $content = $content -creplace [Regex]::Escape('<Product>'), '<Product, long>'
    #     $content = $content -creplace [Regex]::Escape('ProductCreateInput>'), 'ProductCreateInput, long>'
    #     $content = $content -creplace '(class ProductDto.*?EntityDto).*', '$1<long>'

    #     # 修补
    #     $content = $content -creplace [Regex]::Escape('<Product, long>(input'), '<Product>(input'
    #     $content = $content -creplace [Regex]::Escape('DbSet<Product, long>'), 'DbSet<Product>'
    #     $content = $content -creplace [Regex]::Escape('Entity<Product, long>'), 'Entity<Product>'
    #     $content = $content -creplace [Regex]::Escape('EntitySet<Product, long>'), 'EntitySet<Product>'
    # }



    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}

## 处理基础库
function RunLib {
    param (
        $rootPath,
        $projNames
    )

    foreach ($projName in $projNames) {

        Write-Host ("正在处理: $projName")

        $inputRootPath = $rootPath + $projName

        # 获取项目文件遍历
        $files = GetProjFiles -Path $inputRootPath
        foreach ($item in $files) {
            if ($item.FullName.EndsWith('.csproj')) {
                $path = $item.FullName
                $content = ReadFile -Path $path

                $content = $content -creplace [Regex]::Escape('<PackageId>Abp'), '<PackageId>Yoyo.Abp'
                $content = $content -creplace [Regex]::Escape('<Description>Abp'), '<Description>Yoyo.Abp'
                $content = $content -creplace [Regex]::Escape('<AssemblyName>Abp'), '<AssemblyName>Yoyo.Abp'

                WriteFile -Path $path  -Content $content
                continue
            }

            if ($item.FullName.EndsWith('.cs') -eq $false) {
                continue
            }
            ReplaceEntitys -Path $item.FullName
        }
    }
}

## 删除冗余库
function RmLib {
    param (
        $rootPath,
        $projNames
    )
    $dirs = Get-ChildItem -Path $rootPath -Directory
    
    foreach ($item in $dirs) {
        if ($projNames -contains $item.Name) {
            continue 
        }

        $slnPath = Join-Path (Split-Path $rootPath) 'Abp.sln'
        $projPath = Join-Path $rootPath $item.Name
        dotnet sln  "$slnPath" remove  "$projPath"
        Remove-Item -Force -Recurse -Path "$projPath"
    }
    
}

## 处理测试库
function RunTest {
    param (
        $rootPath,
        $projNames
    )
    foreach ($projName in $projNames) {

        Write-Host ("正在处理: $projName")
    
        $inputRootPath = $rootPath + $projName
    
        # 获取项目文件遍历
        $files = GetProjFiles -Path $inputRootPath
        foreach ($item in $files) {
            if (!$item.FullName.EndsWith('.cs') -and !$item.FullName.EndsWith('.sql')) {
                continue
            }
            ReplaceEntitys -Path $item.FullName
            ReplaceTests -Path $item.FullName
        }
    }
}

## 删除冗余库
function RmTest {
    param (
        $rootPath,
        $projNames
    )
    $dirs = Get-ChildItem -Path $rootPath -Directory
    
    foreach ($item in $dirs) {
        if ($projNames -contains $item.Name) {
            continue 
        }

        if ($item.Name -eq 'aspnet-core-demo') {
            continue
        }

        $slnPath = Join-Path (Split-Path $rootPath) 'Abp.sln'
        $projPath = Join-Path $rootPath $item.Name
        dotnet sln  "$slnPath" remove  "$projPath"
        Remove-Item -Force -Recurse -Path "$projPath"
    }
    
}

## 处理测试库中的demos
function RunTestDemos {
    param (
        $rootPath,
        $projNames
    )
    foreach ($projName in $projNames) {

        Write-Host ("正在处理: $projName")
    
        $inputRootPath = $rootPath + $projName

        # 获取项目文件遍历
        $files = GetProjFiles -Path $inputRootPath
        foreach ($item in $files) {
            if (!$item.FullName.EndsWith('.cs') -and !$item.FullName.EndsWith('.sql')) {
                continue
            }
            ReplaceTestDemos -Path $item.FullName
        }
    }
}

# #====================== 基础库
$rootPath = 'D:\dev\github\aspnetboilerplate-7\src\'
$projNames = (
    'Abp',
    'Abp.Web.Common',
    'Abp.AspNetCore',
    'Abp.AspNetCore.OData',
    'Abp.RedisCache',
    'Abp.RedisCache.ProtoBuf',
    'Abp.AspNetCore.PerRequestRedisCache',
    'Abp.AspNetCore.SignalR',
    'Abp.TestBase',
    'Abp.AspNetCore.TestBase',
    'Abp.AutoMapper',
    'Abp.Castle.Log4Net',
    'Abp.Dapper',
    'Abp.EntityFramework.Common',
    'Abp.EntityFramework',
    'Abp.EntityFrameworkCore',
    'Abp.EntityFrameworkCore.EFPlus',
    'Abp.FluentValidation',
    'Abp.HangFire',
    'Abp.HangFire.AspNetCore',
    'Abp.MailKit',
    'Abp.MemoryDb',
    'Abp.MongoDB',
    'Abp.Quartz',
    'Abp.Zero.Common',
    'Abp.Zero.Ldap',
    'Abp.ZeroCore',
    'Abp.ZeroCore.EntityFramework',
    'Abp.ZeroCore.EntityFrameworkCore',
    'Abp.ZeroCore.IdentityServer4',
    'Abp.ZeroCore.IdentityServer4.EntityFrameworkCore',
    'Abp.ZeroCore.IdentityServer4.vNext',
    'Abp.ZeroCore.IdentityServer4.vNext.EntityFrameworkCore'
)


RmLib -rootPath $rootPath -projNames $projNames

RunLib -rootPath $rootPath -projNames $projNames


#====================== 测试
$rootPath = 'D:\dev\github\aspnetboilerplate-7\test\'
$projNames = (
    'Abp.AspNetCore.Tests',
    'Abp.AutoMapper.Tests',
    'Abp.Castle.Log4Net.Tests',
    'Abp.Dapper.Tests',
    'Abp.EntityFramework.Tests',
    'Abp.EntityFrameworkCore.Dapper.Tests',
    'Abp.EntityFrameworkCore.Tests',
    'Abp.MailKit.Tests',
    'Abp.MemoryDb.Tests',
    'Abp.Quartz.Tests',
    'Abp.RedisCache.Tests',
    'Abp.TestBase.Tests',
    'Abp.Tests',
    'Abp.Web.Common.Tests',
    'Abp.ZeroCore.IdentityServer4.Tests',
    'Abp.ZeroCore.SampleApp',
    'Abp.ZeroCore.Tests'
)

RmTest -rootPath $rootPath -projNames $projNames
RunTest -rootPath $rootPath -projNames $projNames


#====================== 测试demos
$rootPath = 'D:\dev\github\aspnetboilerplate-7\test\aspnet-core-demo\'
$projNames = (
    'AbpAspNetCoreDemo',
    'AbpAspNetCoreDemo.Core',
    'AbpAspNetCoreDemo.IntegrationTests',
    'AbpAspNetCoreDemo.PlugIn'
)

RunTestDemos -rootPath $rootPath -projNames $projNames

# ====================== 代码文件移入对应位置
$rootPath = 'D:\dev\github\aspnetboilerplate-7\src\'
$abpZeroCoreEntityFrameworkCorePath = $rootPath + 'Abp.ZeroCore.EntityFrameworkCore\Zero\EntityFrameworkCore\'
Copy-Item './abp/AbpZeroDbContextExtensions.cs' -Destination ($abpZeroCoreEntityFrameworkCorePath + 'AbpZeroDbContextExtensions.cs') -Force

$abpEntityFrameworkCorePath = $rootPath + 'Abp.EntityFrameworkCore\EntityFrameworkCore\Extensions\'
Copy-Item './abp/AbpDbContextExtensions.cs' -Destination ($abpEntityFrameworkCorePath + 'AbpDbContextExtensions.cs') -Force
Copy-Item './abp/AbpStringPrimaryKeyValueGenerator.cs' -Destination ($abpEntityFrameworkCorePath + 'AbpStringPrimaryKeyValueGenerator.cs') -Force

$abpPath = $rootPath + 'Abp\Extensions\'
Copy-Item './abp/StringIdExtensions.cs' -Destination ($abpPath + 'StringIdExtensions.cs') -Force

$rootPath = 'D:\dev\github\aspnetboilerplate-7\'
$nupkgPath = $rootPath + 'nupkg\'
Copy-Item './abp/pack.ps1' -Destination ($nupkgPath + 'pack.ps1') -Force
