using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using Abp.Dapper_Extensions;
using Abp.Dapper_Extensions.Predicate;
using JetBrains.Annotations;

namespace Abp.Dapper.Extensions
{
    internal static class SortingExtensions
    {
        [NotNull]
        public static List<ISort> ToSortable<T>([NotNull] this Expression<Func<T, object>>[] sortingExpression, bool ascending = true)
        {
            Check.NotNullOrEmpty(sortingExpression, nameof(sortingExpression));

            var sortList = new List<ISort>();
            sortingExpression.ToList().ForEach(sortExpression =>
            {
                var sortProperty = DapperExtensionsReflectionHelper.GetProperty(sortExpression) as MemberInfo;
                sortList.Add(new Sort { Ascending = ascending, PropertyName = sortProperty.Name });
            });

            return sortList;
        }
    }
}
