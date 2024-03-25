using Abp.RealTime;
using Shouldly;
using System;
using System.Threading.Tasks;
using Xunit;

namespace Abp.Tests.RealTime
{
    public class InMemoryOnlineClientStore_Tests
    {
        private readonly InMemoryOnlineClientStore _store;
        private readonly InMemoryOnlineClientStore<ChatChannel> _chatStore;

        public InMemoryOnlineClientStore_Tests()
        {
            _store = new InMemoryOnlineClientStore();
            _chatStore = new InMemoryOnlineClientStore<ChatChannel>();
        }

        [Fact]
        public async Task Test_All()
        {
            var connectionId = Guid.NewGuid().ToString("N");

            await _store.AddAsync(new OnlineClient(connectionId, "127.0.0.1", "1", "2"));
            (await _store.TryGetAsync(connectionId, value => _ = value)).ShouldBeTrue();

            (await _store.ContainsAsync(connectionId)).ShouldBeTrue();
            (await _store.GetAllAsync()).Count.ShouldBe(1);
            (await _store.RemoveAsync(connectionId)).ShouldBeTrue();
            (await _store.GetAllAsync()).Count.ShouldBe(0);

            (await _chatStore.GetAllAsync()).Count.ShouldBe(0);
            connectionId = Guid.NewGuid().ToString("N");

            await _chatStore.AddAsync(new OnlineClient(connectionId, "127.0.0.1", "1", "2"));
            (await _chatStore.GetAllAsync()).Count.ShouldBe(1);
        }

        internal class ChatChannel
        {

        }
    }
}
