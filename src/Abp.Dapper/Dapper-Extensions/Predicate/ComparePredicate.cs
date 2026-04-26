using Abp.Dapper_Extensions.Extensions;

namespace Abp.Dapper_Extensions.Predicate
{
    public interface IComparePredicate : IBasePredicate
    {
        Operator Operator { get; set; }
        bool Not { get; set; }
        bool UseTableAlias { get; set; }
    }

    public abstract class ComparePredicate : BasePredicate
    {
        public Operator Operator { get; set; }
        public bool Not { get; set; }
        public bool UseTableAlias { get; set; }

        public virtual string GetOperatorString()
        {
            return Operator.GetString(Not);
        }
    }
}
