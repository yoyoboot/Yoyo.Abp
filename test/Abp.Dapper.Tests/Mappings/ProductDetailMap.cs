using Abp.Dapper_Extensions.Mapper;
using Abp.Dapper.Tests.Entities;

namespace Abp.Dapper.Tests.Mappings
{
    public sealed class ProductDetailMap : ClassMapper<ProductDetail>
    {
        public ProductDetailMap()
        {
            Table("ProductDetails");
            AutoMap();
        }
    }
}
