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
            if ($item.FullName.EndsWith('.csproj')) {
                $path = $item.FullName
                $content = ReadFile -Path $path
                $content = RemoveNetFrameworkCompatibility -Content $content
                WriteFile -Path $path -Content $content
                continue
            }

            if (!$item.FullName.EndsWith('.cs') -and !$item.FullName.EndsWith('.sql')) {
                continue
            }
            ReplaceEntitys -Path $item.FullName
            ReplaceTests -Path $item.FullName
        }
    }
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

    ## SampleAppDbContext.cs
    if (
        [regex]::IsMatch($path, [Regex]::Escape('SampleAppDbContext.cs'))
    ) {
        $content = $content -creplace [Regex]::Escape('modelBuilder.Entity(typeof(CustomEntityWithGuidId));'), @"
modelBuilder.Entity(typeof(CustomEntityWithGuidId));

            modelBuilder.ConfigurationZeroModule<Tenant, Role, User>();
"@
    }

    $content = $content -creplace [Regex]::Escape('__abp'), '__wrapper'

    $content = $content -creplace '(TenantId) = ([0-9].*?[0-9])', '$1 = "$2"'
    $content = $content -creplace [Regex]::Escape(' }"'), '"}'
    $content = $content -creplace [Regex]::Escape('(0")'), '(0)'
    $content = $content -creplace [Regex]::Escape('(1")'), '(0)'
    $content = $content -creplace [Regex]::Escape('"}, Encoding.UTF8,'), '}", Encoding.UTF8,'
    $content = $content -creplace [Regex]::Escape(' }))";'), '" }));'
    # 写入内容到文件
    WriteFile -Path $path  -Content $content
}


