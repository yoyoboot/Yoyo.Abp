using System.Collections.Generic;
using Abp.Dapper_Extensions.Sql;

namespace Abp.Dapper_Extensions.Predicate
{
    public interface IPredicate
    {
        string GetSql(ISqlGenerator sqlGenerator, IDictionary<string, object> parameters, bool isDml = false);
    }
}
