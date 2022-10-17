using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Abp.Configuration;
using Abp.Configuration.Startup;
using Abp.Domain.Uow;
using Abp.MultiTenancy;
using Abp.Runtime.Caching.Configuration;
using Abp.Runtime.Caching.Memory;
using Abp.Runtime.Remoting;
using Abp.Runtime.Session;
using Abp.TestBase.Runtime.Session;
using Abp.Tests.MultiTenancy;
using Castle.MicroKernel.Registration;
using NSubstitute;
using Shouldly;
using Xunit;

namespace Abp.Tests.Configuration
{
    public class SettingManager_Tests : TestBaseWithLocalIocManager
    {
        private enum MyEnumSettingType
        {
            Setting1 = 0,
            Setting2 = 1,
        }

        private const string MyAppLevelSetting = "MyAppLevelSetting";
        private const string MyAllLevelsSetting = "MyAllLevelsSetting";
        private const string MyNotInheritedSetting = "MyNotInheritedSetting";
        private const string MyEnumTypeSetting = "MyEnumTypeSetting";
        private const string MyEncryptedSetting = "MyEncryptedSetting";

        private SettingManager CreateSettingManager(bool multiTenancyIsEnabled = true)
        {
            return new SettingManager(
                CreateMockSettingDefinitionManager(),
                new AbpMemoryCacheManager(
                    new CachingConfiguration(Substitute.For<IAbpStartupConfiguration>())
                ),
                new MultiTenancyConfig
                {
                    IsEnabled = multiTenancyIsEnabled
                }, new TestTenantStore(),
                new SettingEncryptionService(new SettingsConfiguration()),
                Substitute.For<IUnitOfWorkManager>());
        }

        [Fact]
        public async Task Should_Get_Default_Values_With_No_Store_And_No_Session()
        {
            var settingManager = CreateSettingManager();

            (await settingManager.GetSettingValueAsync<int>(MyAppLevelSetting)).ShouldBe(42);
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("application level default value");
        }

        [Fact]
        public async Task Should_Get_Stored_Application_Value_With_No_Session()
        {
            var settingManager = CreateSettingManager();
            settingManager.SettingStore = new MemorySettingStore();

            (await settingManager.GetSettingValueAsync<int>(MyAppLevelSetting)).ShouldBe(48);
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("application level stored value");
        }

        [Fact]
        public async Task Should_Get_Correct_Values()
        {
            var session = CreateTestAbpSession();

            var settingManager = CreateSettingManager();
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            session.TenantId = "1";

            //Inherited setting

            session.UserId = "1";
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("user 1 stored value");

            session.UserId = "2";
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("user 2 stored value");

            session.UserId = "3";
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting))
                .ShouldBe("tenant 1 stored value"); //Because no user value in the store

            session.TenantId = "3";
            session.UserId = "3";
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting))
                .ShouldBe("application level stored value"); //Because no user and tenant value in the store

            //Not inherited setting

            session.TenantId = "1";
            session.UserId = "1";

            (await settingManager.GetSettingValueForApplicationAsync(MyNotInheritedSetting)).ShouldBe(
                "application value");
            (await settingManager.GetSettingValueForTenantAsync(MyNotInheritedSetting, session.TenantId))
                .ShouldBe("default-value");
            (await settingManager.GetSettingValueAsync(MyNotInheritedSetting)).ShouldBe("default-value");

            (await settingManager.GetSettingValueAsync<MyEnumSettingType>(MyEnumTypeSetting)).ShouldBe(MyEnumSettingType
                .Setting1);
        }

        [Fact]
        public async Task Should_Get_All_Values()
        {
            var settingManager = CreateSettingManager();
            settingManager.SettingStore = new MemorySettingStore();

            (await settingManager.GetAllSettingValuesAsync()).Count.ShouldBe(5);

            (await settingManager.GetAllSettingValuesForApplicationAsync()).Count.ShouldBe(4);

            (await settingManager.GetAllSettingValuesForTenantAsync("1")).Count.ShouldBe(2);
            (await settingManager.GetAllSettingValuesForTenantAsync("1")).Count.ShouldBe(2);
            (await settingManager.GetAllSettingValuesForTenantAsync("2")).Count.ShouldBe(0);
            (await settingManager.GetAllSettingValuesForTenantAsync("3")).Count.ShouldBe(0);

            (await settingManager.GetAllSettingValuesForUserAsync(new UserIdentifier("1","1"))).Count.ShouldBe(1);
            (await settingManager.GetAllSettingValuesForUserAsync(new UserIdentifier("1","2"))).Count.ShouldBe(2);
            (await settingManager.GetAllSettingValuesForUserAsync(new UserIdentifier("1","3"))).Count.ShouldBe(0);
        }

        [Fact]
        public async Task Should_Change_Setting_Values()
        {
            var session = CreateTestAbpSession();

            var settingManager = CreateSettingManager();
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            //Application level changes

            await settingManager.ChangeSettingForApplicationAsync(MyAppLevelSetting, "53");
            await settingManager.ChangeSettingForApplicationAsync(MyAppLevelSetting, "54");
            await settingManager.ChangeSettingForApplicationAsync(MyAllLevelsSetting,
                "application level changed value");

            (await settingManager.SettingStore.GetSettingOrNullAsync(null, null, MyAppLevelSetting)).Value
                .ShouldBe("54");

            (await settingManager.GetSettingValueAsync<int>(MyAppLevelSetting)).ShouldBe(54);
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("application level changed value");

            //Tenant level changes

            session.TenantId = "1";
            await settingManager.ChangeSettingForTenantAsync("1", MyAllLevelsSetting, "tenant 1 changed value");
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("tenant 1 changed value");

            //User level changes

            session.UserId = "1";
            await settingManager.ChangeSettingForUserAsync("1", MyAllLevelsSetting, "user 1 changed value");
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("user 1 changed value");
        }

        [Fact]
        public async Task Should_Delete_Setting_Values_On_Default_Value()
        {
            var session = CreateTestAbpSession();
            var store = new MemorySettingStore();

            var settingManager = CreateSettingManager();
            settingManager.SettingStore = store;
            settingManager.AbpSession = session;

            session.TenantId = "1";
            session.UserId = "1";

            //We can get user's personal stored value
            (await store.GetSettingOrNullAsync("1", "1", MyAllLevelsSetting)).ShouldNotBe(null);
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("user 1 stored value");

            //This will delete setting for the user since it's same as tenant's setting value
            await settingManager.ChangeSettingForUserAsync("1", MyAllLevelsSetting, "tenant 1 stored value");
            (await store.GetSettingOrNullAsync("1", "1", MyAllLevelsSetting)).ShouldBe(null);

            //We can get tenant's setting value
            (await store.GetSettingOrNullAsync("1", null, MyAllLevelsSetting)).ShouldNotBe(null);
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("tenant 1 stored value");

            //This will delete setting for tenant since it's same as application's setting value
            await settingManager.ChangeSettingForTenantAsync("1", MyAllLevelsSetting, "application level stored value");
            (await store.GetSettingOrNullAsync("1", "1", MyAllLevelsSetting)).ShouldBe(null);

            //We can get application's value
            (await store.GetSettingOrNullAsync(null, null, MyAllLevelsSetting)).ShouldNotBe(null);
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("application level stored value");

            //This will delete setting for application since it's same as the default value of the setting
            await settingManager.ChangeSettingForApplicationAsync(MyAllLevelsSetting,
                "application level default value");
            (await store.GetSettingOrNullAsync(null, null, MyAllLevelsSetting)).ShouldBe(null);

            //Now, there is no setting value, default value should return
            (await settingManager.GetSettingValueAsync(MyAllLevelsSetting)).ShouldBe("application level default value");
        }

        [Fact]
        public async Task Should_Save_Application_Level_Setting_As_Tenant_Setting_When_Multi_Tenancy_Is_Disabled()
        {
            // Arrange
            var session = CreateTestAbpSession(multiTenancyIsEnabled: false);

            var settingManager = CreateSettingManager(multiTenancyIsEnabled: false);
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            // Act
            await settingManager.ChangeSettingForApplicationAsync(MyAllLevelsSetting, "53");

            // Assert
            var value = await settingManager.GetSettingValueAsync(MyAllLevelsSetting);
            value.ShouldBe("53");
        }

        [Fact]
        public async Task Should_Get_Tenant_Setting_For_Application_Level_Setting_When_Multi_Tenancy_Is_Disabled()
        {
            // Arrange
            var session = CreateTestAbpSession(multiTenancyIsEnabled: false);

            var settingManager = CreateSettingManager(multiTenancyIsEnabled: false);
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            // Act
            await settingManager.ChangeSettingForApplicationAsync(MyAllLevelsSetting, "53");

            // Assert
            var value = await settingManager.GetSettingValueForApplicationAsync(MyAllLevelsSetting);
            value.ShouldBe("53");
        }

        [Fact]
        public async Task Should_Change_Setting_Value_When_Multi_Tenancy_Is_Disabled()
        {
            // Arrange
            var session = CreateTestAbpSession(multiTenancyIsEnabled: false);

            var settingManager = CreateSettingManager(multiTenancyIsEnabled: false);
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            //change setting value with "B"
            await settingManager.ChangeSettingForApplicationAsync(MyAppLevelSetting, "B");

            // it's ok
            (await settingManager.GetSettingValueForApplicationAsync(MyAppLevelSetting)).ShouldBe("B");

            //change setting with same value "B" again,
            await settingManager.ChangeSettingForApplicationAsync(MyAppLevelSetting, "B");

            //but was "A" ,that's wrong
            (await settingManager.GetSettingValueForApplicationAsync(MyAppLevelSetting)).ShouldBe("B");
        }

        [Fact]
        public async Task Should_Get_Encrypted_Setting_Value()
        {
            var session = CreateTestAbpSession();

            var settingManager = CreateSettingManager();
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            session.TenantId = "1";

            // User setting
            session.UserId = "2";
            (await settingManager.GetSettingValueAsync(MyEncryptedSetting)).ShouldBe("user_setting");

            // Tenant setting
            session.UserId = null;
            (await settingManager.GetSettingValueAsync(MyEncryptedSetting)).ShouldBe("tenant_setting");

            // App setting
            session.TenantId = null;
            (await settingManager.GetSettingValueAsync(MyEncryptedSetting)).ShouldBe("app_setting");
        }

        [Fact]
        public async Task Should_Set_Encrypted_Setting_Value()
        {
            var session = CreateTestAbpSession();

            var settingManager = CreateSettingManager();
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            session.TenantId = "1";

            // User setting
            session.UserId = "2";
            await settingManager.ChangeSettingForUserAsync(session.ToUserIdentifier(), MyEncryptedSetting,
                "user_123qwe");

            var settingValue = await settingManager.SettingStore.GetSettingOrNullAsync(
                session.TenantId,
                session.UserId,
                MyEncryptedSetting
            );

            settingValue.Value.ShouldBe("oKPqQDCAHhz+AEnl/r0fsw==");

            // Tenant setting
            session.UserId = null;
            await settingManager.ChangeSettingForTenantAsync(session.GetTenantId(), MyEncryptedSetting,
                "tenant_123qwe");

            settingValue = await settingManager.SettingStore.GetSettingOrNullAsync(
                session.TenantId,
                session.UserId,
                MyEncryptedSetting
            );

            settingValue.Value.ShouldBe("YX+MTwbuOwXgL7tnKw+oxw==");

            // App setting
            session.TenantId = null;
            await settingManager.ChangeSettingForApplicationAsync(MyEncryptedSetting, "app_123qwe");

            settingValue = await settingManager.SettingStore.GetSettingOrNullAsync(
                session.TenantId,
                session.UserId,
                MyEncryptedSetting
            );

            settingValue.Value.ShouldBe("EOi2wcQt1pi1K4qYycBBbg==");
        }

        [Fact]
        public async Task Should_Get_Changed_Encrypted_Setting_Value()
        {
            var session = CreateTestAbpSession();

            var settingManager = CreateSettingManager();
            settingManager.SettingStore = new MemorySettingStore();
            settingManager.AbpSession = session;

            session.TenantId = "1";

            // User setting
            session.UserId = "2";

            await settingManager.ChangeSettingForUserAsync(
                session.ToUserIdentifier(),
                MyEncryptedSetting,
                "new_user_setting"
            );

            var settingValue = await settingManager.GetSettingValueAsync(MyEncryptedSetting);
            settingValue.ShouldBe("new_user_setting");

            // Tenant Setting
            session.UserId = null;

            await settingManager.ChangeSettingForTenantAsync(
                session.GetTenantId(),
                MyEncryptedSetting,
                "new_tenant_setting"
            );

            settingValue = await settingManager.GetSettingValueAsync(MyEncryptedSetting);
            settingValue.ShouldBe("new_tenant_setting");

            // App Setting
            session.TenantId = null;

            await settingManager.ChangeSettingForApplicationAsync(
                MyEncryptedSetting,
                "new_app_setting"
            );

            settingValue = await settingManager.GetSettingValueAsync(MyEncryptedSetting);
            settingValue.ShouldBe("new_app_setting");
        }

        private static TestAbpSession CreateTestAbpSession(bool multiTenancyIsEnabled = true)
        {
            return new TestAbpSession(
                new MultiTenancyConfig {IsEnabled = multiTenancyIsEnabled},
                new DataContextAmbientScopeProvider<SessionOverride>(
                    new AsyncLocalAmbientDataContext()
                ),
                Substitute.For<ITenantResolver>()
            );
        }

        private static ISettingDefinitionManager CreateMockSettingDefinitionManager()
        {
            var settings = new Dictionary<string, SettingDefinition>
            {
                {MyAppLevelSetting, new SettingDefinition(MyAppLevelSetting, "42")},
                {
                    MyAllLevelsSetting,
                    new SettingDefinition(MyAllLevelsSetting, "application level default value",
                        scopes: SettingScopes.Application | SettingScopes.Tenant | SettingScopes.User)
                },
                {
                    MyNotInheritedSetting,
                    new SettingDefinition(MyNotInheritedSetting, "default-value",
                        scopes: SettingScopes.Application | SettingScopes.Tenant, isInherited: false)
                },
                {MyEnumTypeSetting, new SettingDefinition(MyEnumTypeSetting, MyEnumSettingType.Setting1.ToString())},
                {
                    MyEncryptedSetting,
                    new SettingDefinition(MyEncryptedSetting, "", isEncrypted: true,
                        scopes: SettingScopes.Application | SettingScopes.Tenant | SettingScopes.User)
                }
            };

            var definitionManager = Substitute.For<ISettingDefinitionManager>();

            //Implement methods
            definitionManager.GetSettingDefinition(Arg.Any<string>()).Returns(x =>
            {
                if (!settings.TryGetValue(x[0].ToString(), out var settingDefinition))
                {
                    throw new AbpException("There is no setting defined with name: " + x[0]);
                }

                return settingDefinition;
            });
            definitionManager.GetAllSettingDefinitions().Returns(settings.Values.ToList());

            return definitionManager;
        }

        private class MemorySettingStore : ISettingStore
        {
            private readonly List<SettingInfo> _settings;

            public MemorySettingStore()
            {
                _settings = new List<SettingInfo>
                {
                    new SettingInfo(null, null, MyAppLevelSetting, "48"),
                    new SettingInfo(null, null, MyAllLevelsSetting, "application level stored value"),
                    new SettingInfo("1", null, MyAllLevelsSetting, "tenant 1 stored value"),
                    new SettingInfo("1", "1", MyAllLevelsSetting, "user 1 stored value"),
                    new SettingInfo("1", "2", MyAllLevelsSetting, "user 2 stored value"),
                    new SettingInfo("1", "2", MyEncryptedSetting,
                        "Bs90qo8Argqw3l4ZfWsRqQ=="), // encrypted setting: user_setting
                    new SettingInfo("1", null, MyEncryptedSetting,
                        "f1dilIUWtfL7DhGextUFKw=="), // encrypted setting: tenant_setting
                    new SettingInfo(null, null, MyEncryptedSetting,
                        "OsxLBbqIX7jiqOXo3M1DdA=="), // encrypted setting: app_setting
                    new SettingInfo(null, null, MyNotInheritedSetting, "application value"),
                };
            }

            public Task<SettingInfo> GetSettingOrNullAsync(string tenantId, string userId, string name)
            {
                return Task.FromResult(GetSettingOrNull(tenantId, userId, name));
            }

            public SettingInfo GetSettingOrNull(string tenantId, string userId, string name)
            {
                return _settings.FirstOrDefault(s => s.TenantId == tenantId && s.UserId == userId && s.Name == name);
            }

#pragma warning disable 1998
            public Task DeleteAsync(SettingInfo setting)
            {
                Delete(setting);
                return Task.CompletedTask;
            }

            public void Delete(SettingInfo setting)
            {
                _settings.RemoveAll(s =>
                    s.TenantId == setting.TenantId && s.UserId == setting.UserId && s.Name == setting.Name);
            }
#pragma warning restore 1998

#pragma warning disable 1998
            public Task CreateAsync(SettingInfo setting)
            {
                Create(setting);
                return Task.CompletedTask;
            }

            public void Create(SettingInfo setting)
            {
                _settings.Add(setting);
            }
#pragma warning restore 1998

            public Task UpdateAsync(SettingInfo setting)
            {
                Update(setting);
                return Task.CompletedTask;
            }

            public void Update(SettingInfo setting)
            {
                var s = GetSettingOrNull(setting.TenantId, setting.UserId, setting.Name);
                if (s != null)
                {
                    s.Value = setting.Value;
                }
            }

            public Task<List<SettingInfo>> GetAllListAsync(string tenantId, string userId)
            {
                return Task.FromResult(GetAllList(tenantId, userId));
            }

            public List<SettingInfo> GetAllList(string tenantId, string userId)
            {
                var allSetting = _settings.Where(s => s.TenantId == tenantId && s.UserId == userId)
                    .Select(s => new SettingInfo(s.TenantId, s.UserId, s.Name, s.Value)).ToList();

                //Add some undefined settings.
                allSetting.Add(new SettingInfo(null, null, Guid.NewGuid().ToString(), Guid.NewGuid().ToString()));
                allSetting.Add(new SettingInfo("1", null, Guid.NewGuid().ToString(), Guid.NewGuid().ToString()));
                allSetting.Add(new SettingInfo("1", "1", Guid.NewGuid().ToString(), Guid.NewGuid().ToString()));

                return allSetting;
            }
        }
    }
}
