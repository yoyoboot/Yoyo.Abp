
# 执行公用脚本
. '.\common.ps1'
. '.\func.ps1'


# 替换实体主键
function ReplaceEntitys {
    param (
        [string]$path
    )

    # 读取文件内容
    $content = ReadFile -Path $path
     
    $content = $content -ireplace [Regex]::Escape('Entity<long>'), 'Entity<string>'
    $content = $content -ireplace [Regex]::Escape('Entity<int>'), 'Entity<string>'
    $content = $content -ireplace [Regex]::Escape('AggregateRoot<int>'), 'AggregateRoot<string>'
    $content = $content -ireplace [Regex]::Escape('EntityDto<long?>'), 'EntityDto<string>'
    $content = $content -ireplace [Regex]::Escape('EntityDto<long>'), 'EntityDto<string>'
    $content = $content -ireplace [Regex]::Escape('EntityDto<int?>'), 'EntityDto<string>'
    $content = $content -ireplace [Regex]::Escape('EntityDto<int>'), 'EntityDto<string>'

    $content = $content -ireplace [Regex]::Escape('EntityCache<TCacheItem, int>'), 'EntityCache<TCacheItem, string>'
    $content = $content -ireplace [Regex]::Escape('EntityCache<TEntity, TCacheItem, int>'), 'EntityCache<TEntity, TCacheItem, string>'

    $content = $content -ireplace [Regex]::Escape('AsyncCrudAppService<TEntityDto, int'), 'AsyncCrudAppService<TEntityDto, string'
    $content = $content -ireplace [Regex]::Escape('CrudAppService<TEntity, TEntityDto, int'), 'CrudAppService<TEntity, TEntityDto, string'
    $content = $content -ireplace [Regex]::Escape('CrudAppService<TEntityDto, int'), 'CrudAppService<TEntityDto, string'

    $content = $content -ireplace [Regex]::Escape('Repository<TEntity, int>'), 'Repository<TEntity, string>'
    $content = $content -ireplace [Regex]::Escape('Repository<EntityChange, long>'), 'Repository<EntityChange, string>'


    $content = $content -ireplace [Regex]::Escape('long? DeleterUserId'), 'string DeleterUserId'
    $content = $content -ireplace [Regex]::Escape('long? LastModifierUserId'), 'string LastModifierUserId'
    $content = $content -ireplace [Regex]::Escape('long? CreatorUserId'), 'string CreatorUserId'

    ## 租户id
    $content = $content -ireplace [Regex]::Escape('TenantId.HasValue'), 'TenantId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('tenantId.HasValue'), 'tenantId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('_tenantId.HasValue'), '_tenantId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('int TenantId'), 'string TenantId'
    $content = $content -ireplace [Regex]::Escape('int? TenantId'), 'string TenantId'
    $content = $content -ireplace [Regex]::Escape('int tenantId'), 'string tenantId'
    $content = $content -ireplace [Regex]::Escape('int? tenantId'), 'string tenantId'
    $content = $content -ireplace [Regex]::Escape('int? notificationId'), 'string notificationId'


    ## 用户Id
    $content = $content -ireplace [Regex]::Escape('UserId.HasValue'), 'UserId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('userId.HasValue'), 'userId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('_userId.HasValue'), '_userId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('long UserId'), 'string UserId'
    $content = $content -ireplace [Regex]::Escape('long? UserId'), 'string UserId'
    $content = $content -ireplace [Regex]::Escape('long userId'), 'string userId'
    $content = $content -ireplace [Regex]::Escape('long? userId'), 'string userId'
    $content = $content -ireplace [Regex]::Escape('int userId'), 'string userId'
    $content = $content -ireplace [Regex]::Escape('int? userId'), 'string userId'


    ## 模拟登录
    $content = $content -ireplace [Regex]::Escape('ImpersonatorTenantId.HasValue'), 'ImpersonatorTenantId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('int? ImpersonatorTenantId'), 'string ImpersonatorTenantId'
    $content = $content -ireplace [Regex]::Escape('int ImpersonatorTenantId'), 'string ImpersonatorTenantId'
    $content = $content -ireplace [Regex]::Escape('int? impersonatorTenantId'), 'string impersonatorTenantId'
    $content = $content -ireplace [Regex]::Escape('int impersonatorTenantId'), 'string impersonatorTenantId'

    $content = $content -ireplace [Regex]::Escape('ImpersonatorUserId.HasValue'), 'ImpersonatorUserId.HasValue()'
    $content = $content -ireplace [Regex]::Escape('long? ImpersonatorUserId'), 'string ImpersonatorUserId'
    $content = $content -ireplace [Regex]::Escape('long ImpersonatorUserId'), 'string ImpersonatorUserId'
    $content = $content -ireplace [Regex]::Escape('long? impersonatorUserId'), 'string impersonatorUserId'
    $content = $content -ireplace [Regex]::Escape('long impersonatorUserId'), 'string impersonatorUserId'

    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}


# 替换功能的
function ReplaceF {
    param (
        [string]$path
    )

    # 读取文件内容
    $content = ReadFile -Path $path
     
    $content = $content -ireplace [Regex]::Escape('TenantInfo Find([NotNull] string tenancyName);'), 'TenantInfo Find([NotNull] string tenancyName);'
   

    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}

$inputRootPath = 'D:\dev\github\aspnetboilerplate\src\Abp'

# 获取项目文件
$files = GetProjFiles -Path $inputRootPath


foreach ($item in $files) {
    if ($item.FullName.EndsWith('.cs') -eq $false) {
        continue
    }

    ReplaceEntitys -Path $item.FullName
}