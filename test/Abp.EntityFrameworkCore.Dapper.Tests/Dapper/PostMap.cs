using Abp.Dapper_Extensions.Mapper;
using Abp.EntityFrameworkCore.Dapper.Tests.Domain;

namespace Abp.EntityFrameworkCore.Dapper.Tests.Dapper;

public class PostMap : ClassMapper<Post>
{
    public PostMap()
    {
        Table("Posts");
        Map(x => x.Id).Key(KeyType.Guid);
        Map(x => x.Blog).Ignore();
        Map(x => x.Comment).Ignore();
        AutoMap();
    }
}
