using Abp.Dapper_Extensions.Mapper;
using Abp.EntityFrameworkCore.Dapper.Tests.Domain;

namespace Abp.EntityFrameworkCore.Dapper.Tests.Dapper;

public sealed class CommentMap : ClassMapper<Comment>
{
    public CommentMap()
    {
        Table("Comments");
        Map(x => x.Id).Key(KeyType.Identity);
        AutoMap();
    }
}
