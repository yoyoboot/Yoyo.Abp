using Abp.Dapper_Extensions.Mapper;
using Abp.Dapper.Tests.Entities;

namespace Abp.Dapper.Tests.Mappings
{
    public sealed class ProductMap : ClassMapper<Product>
    {
        public ProductMap()
        {
            Table("Products");
            Map(x => x.Id).Key(KeyType.Identity);
            AutoMap();
        }
    }
}
