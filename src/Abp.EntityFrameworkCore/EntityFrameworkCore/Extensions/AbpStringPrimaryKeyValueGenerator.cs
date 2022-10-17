using Abp.Domain.Entities;

using JetBrains.Annotations;

using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.ValueGeneration;

namespace Abp.EntityFrameworkCore
{
    public class AbpStringPrimaryKeyValueGenerator : ValueGenerator<string>
    {
        public override bool GeneratesTemporaryValues => false;

        public override string Next([NotNull] EntityEntry entry)
        {
            var entity = entry.Entity as IEntity<string>;
            if (entity != null && entity.Id.HasValue())
            {
                return entity.Id;
            }

            return SequentialGuidGenerator.Instance.Create().ToString("N");
        }
    }
}
