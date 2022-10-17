using System.Collections.Generic;
using Abp.Events.Bus;

namespace Abp.Domain.Entities
{
    public interface IAggregateRoot : IAggregateRoot<string>, IEntity
    {

    }

    public interface IAggregateRoot<TPrimaryKey> : IEntity<TPrimaryKey>, IGeneratesDomainEvents
    {

    }

    public interface IGeneratesDomainEvents
    {
        ICollection<IEventData> DomainEvents { get; }
    }
}
