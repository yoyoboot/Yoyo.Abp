function RemoveNetFrameworkCompatibility {
    param (
        $Content
    )

    $contentText = $Content -join [Environment]::NewLine

    $contentText = $contentText -creplace '(?s)\s*<ItemGroup\s+Condition="\s*''\$\(TargetFramework\)''\s*==\s*''net4\d+''\s*"\s*>.*?</ItemGroup>', ''
    $contentText = $contentText -creplace '(?s)\s*<PropertyGroup\s+Condition="\s*''\$\(TargetFramework\)''\s*==\s*''net4\d+''\s*"\s*>.*?</PropertyGroup>', ''
    $contentText = $contentText -creplace 'portable-net45\+win8\+wp8\+wpa81;?', ''
    $contentText = $contentText -creplace '<AssetTargetFallback>\$\(AssetTargetFallback\);?</AssetTargetFallback>\s*', ''

    $contentText = [Regex]::Replace($contentText, '<TargetFrameworks>(.*?)</TargetFrameworks>', {
            param($match)

            $frameworks = @($match.Groups[1].Value -split ';' | Where-Object { $_ -and ($_ -notmatch '^net4\d+$') })

            if ($frameworks.Count -eq 0) {
                return '<TargetFramework>net6.0</TargetFramework>'
            }

            if ($frameworks.Count -eq 1) {
                return "<TargetFramework>$($frameworks[0])</TargetFramework>"
            }

            return "<TargetFrameworks>$($frameworks -join ';')</TargetFrameworks>"
        })

    $contentText = $contentText -creplace '<TargetFramework>net4\d+</TargetFramework>', '<TargetFramework>net6.0</TargetFramework>'

    return $contentText
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

        if ($item.Name -eq 'aspnet-core-demo') {
            continue
        }

        $slnPath = Join-Path (Split-Path $rootPath) 'Abp.sln'
        $projPath = Join-Path $rootPath $item.Name
        dotnet sln  "$slnPath" remove  "$projPath"
        Remove-Item -Force -Recurse -Path "$projPath"
    }

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
                $content = RemoveNetFrameworkCompatibility -Content $content

                WriteFile -Path $path  -Content $content
                continue
            }

            if (!$item.FullName.EndsWith('.cs')) {
                continue
            }

            ReplaceEntitys -Path $item.FullName
        }
    }
}

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
    ## AutoMapExtensions.cs
    if ($path.EndsWith('AutoMapExtensions.cs')) {
        $content = $content -creplace [Regex]::Escape('CreateMultiLingualMap<TMultiLingualEntity, TMultiLingualEntityPrimaryKey, TTranslation, TTranslationPrimaryKey, TDestination>('), 'CreateMultiLingualMap<TMultiLingualEntity, TMultiLingualEntityPrimaryKey, TTranslation, TDestination>('
        $content = $content -creplace [Regex]::Escape('where TTranslation : class, IEntityTranslation<TMultiLingualEntity, TMultiLingualEntityPrimaryKey>, IEntity<TTranslationPrimaryKey>'), 'where TTranslation : class, IEntityTranslation<TMultiLingualEntity, TMultiLingualEntityPrimaryKey>'
        $content = $content -creplace [Regex]::Escape('CreateMultiLingualMap<TMultiLingualEntity, int, TTranslation, int, TDestination>('), 'CreateMultiLingualMap<TMultiLingualEntity, int, TTranslation, TDestination>('
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
    if ($path.EndsWith('SessionScriptManager.cs')) {
        $content = $content -creplace [Regex]::Escape('AbpSession.UserId : "null"'), '$"\"{AbpSession.UserId}\"" : "\"null\""'
        $content = $content -creplace [Regex]::Escape('AbpSession.TenantId : "null"'), '$"\"{AbpSession.TenantId}\"" : "\"null\""'
        $content = $content -creplace [Regex]::Escape('AbpSession.ImpersonatorUserId : "null"'), '$"\"{AbpSession.ImpersonatorUserId}\"" : "\"null\""'
        $content = $content -creplace [Regex]::Escape('AbpSession.ImpersonatorTenantId : "null"'), '$"\"{AbpSession.ImpersonatorTenantId}\"" : "\"null\""'
        $content = $content -creplace [Regex]::Escape('\"'), "'"
    }
    if ($path.EndsWith('AbpODataDtoController.cs')) {
        $content = $content -creplace [Regex]::Escape('AbpODataDtoController<TEntity, TOutputDto, TInputDto, int>'), 'AbpODataDtoController<TEntity, TOutputDto, TInputDto, string>'
    }

    $content = $content -creplace [Regex]::Escape('ParentId.HasValue'), 'ParentId.HasValue()'
    $content = $content -creplace [Regex]::Escape('parentId.HasValue'), 'parentId.HasValue()'
    $content = $content -creplace [Regex]::Escape('ParentId.Value'), 'ParentId'
    $content = $content -creplace [Regex]::Escape('parentId.Value'), 'parentId'
    $content = $content -creplace [Regex]::Escape('long? parentId'), 'string parentId'
    $content = $content -creplace [Regex]::Escape('long? ParentId'), 'string ParentId'
    $content = $content -creplace [Regex]::Escape('int RoleId'), 'string RoleId'

    $content = $content -creplace [Regex]::Escape('__abp'), '__wrapper'


    # 写入内容到文件
    $content = $content -creplace [Regex]::Escape('.HasValue()()'), '.HasValue()'
    $content = $content -creplace [Regex]::Escape('t.TenantId==""()'), 't.TenantId==""'
    WriteFile -Path $path  -Content $content
}
