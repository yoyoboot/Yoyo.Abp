using Abp.Domain.Entities;
using Abp.Events.Bus.Entities;
using Abp.Events.Bus.Handlers;
using Shouldly;
using System.Threading.Tasks;
using Xunit;

namespace Abp.Tests.Events.Bus
{
    public class EventBus_EntityEvents_Test : EventBusTestBase
    {
        [Fact]
        public void Should_Call_Created_And_Changed_Once()
        {
            var handler = new MyEventHandler();

            EventBus.Register<EntityChangedEventData<MyEntity>>(handler);
            EventBus.Register<EntityCreatedEventData<MyEntity>>(handler);

            var asyncHandler = new MyAsyncEventHandler();

            EventBus.AsyncRegister<EntityChangedEventData<MyEntity>>(asyncHandler);
            EventBus.AsyncRegister<EntityCreatedEventData<MyEntity>>(asyncHandler);

            EventBus.Trigger(new EntityCreatedEventData<MyEntity>(new MyEntity()));

            handler.EntityCreatedEventCount.ShouldBe(1);
            handler.EntityChangedEventCount.ShouldBe(1);

            asyncHandler.EntityCreatedEventCount.ShouldBe(1);
            asyncHandler.EntityChangedEventCount.ShouldBe(1);
        }

        public class MyEntity : Entity
        {
            
        }

        public class MyEventHandler : 
            IEventHandler<EntityChangedEventData<MyEntity>>,
            IEventHandler<EntityCreatedEventData<MyEntity>>
        {
            public int EntityChangedEventCount { get; set; }
            public int EntityCreatedEventCount { get; set; }

            public void HandleEvent(EntityChangedEventData<MyEntity> eventData)
            {
                EntityChangedEventCount++;
            }

            public void HandleEvent(EntityCreatedEventData<MyEntity> eventData)
            {
                EntityCreatedEventCount++;
            }
        }

        public class MyAsyncEventHandler :
            IAsyncEventHandler<EntityChangedEventData<MyEntity>>,
            IAsyncEventHandler<EntityCreatedEventData<MyEntity>>
        {
            public int EntityChangedEventCount { get; set; }
            public int EntityCreatedEventCount { get; set; }

            public Task HandleEventAsync(EntityChangedEventData<MyEntity> eventData)
            {
                EntityChangedEventCount++;
                return Task.FromResult(0);
            }

            public Task HandleEventAsync(EntityCreatedEventData<MyEntity> eventData)
            {
                EntityCreatedEventCount++;
                return Task.FromResult(0);
            }
        }
    }
}
