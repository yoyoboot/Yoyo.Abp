using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using Abp.RealTime;
using Shouldly;
using Xunit;

namespace Abp.Tests.RealTime
{
    public class InMemoryOnlineClientManager_Tests
    {
        private readonly IOnlineClientManager _clientManager;
        private static readonly RandomNumberGenerator KeyGenerator = RandomNumberGenerator.Create();

        public InMemoryOnlineClientManager_Tests()
        {
            
            _clientManager = new OnlineClientManager(new InMemoryOnlineClientStore());
        }

        [Fact]
        public void Test_All()
        {
            string tenantId = "1";

            Dictionary<string, string> connections = new Dictionary<string, string>();

            for (int i = 0; i < 100; i++)
            {
                connections.Add(MakeNewConnectionId(), (i + 1).ToString());
            }

            foreach (var pair in connections)
            {
                _clientManager.Add(new OnlineClient(pair.Key, "127.0.0.1", tenantId, pair.Value));
            }

            var testId = connections.Keys.ToList()[5];

            _clientManager.GetAllClients().Count.ShouldBe(connections.Count);
            _clientManager.GetAllByUserId(new UserIdentifier(tenantId, connections[testId])).Count.ShouldBe(1);
            _clientManager.GetByConnectionIdOrNull(testId).ShouldNotBeNull();
            _clientManager.Remove(testId).ShouldBeTrue();
            _clientManager.GetAllClients().Count.ShouldBe(connections.Count - 1);
            _clientManager.GetByConnectionIdOrNull(testId).ShouldBeNull();
            _clientManager.GetAllByUserId(new UserIdentifier(tenantId, connections[testId])).Count.ShouldBe(0);
        }

        private static string MakeNewConnectionId()
        {
            var buffer = new byte[16];
            KeyGenerator.GetBytes(buffer);
            return Convert.ToBase64String(buffer);
        }
    }
}
