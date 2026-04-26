using Abp.Dapper_Extensions.Mapper;
using Abp.Dapper.Tests.Entities;

namespace Abp.Dapper.Tests.Mappings
{
    public sealed class PersonMap : ClassMapper<Person>
    {
        public PersonMap()
        {
            Table("Person");
            Map(x => x.Id).Key(KeyType.Identity);
            AutoMap();
        }
    }
}
