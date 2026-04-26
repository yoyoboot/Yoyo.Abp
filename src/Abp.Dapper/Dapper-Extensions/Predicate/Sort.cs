using System.Collections.Generic;
using System.Reflection;

namespace Abp.Dapper_Extensions.Predicate
{
    public interface ISort
    {
        string PropertyName { get; set; }
        bool Ascending { get; set; }
        IList<PropertyInfo> Properties { get; set; }
    }

    public class Sort : ISort
    {
        public string PropertyName { get; set; }
        public bool Ascending { get; set; }
        public IList<PropertyInfo> Properties { get; set; }

        public Sort()
        {
            Properties = new List<PropertyInfo>();
        }
    }
}
