using Abp.Domain.Entities;
using System.ComponentModel.DataAnnotations.Schema;

namespace Abp.Dapper.Tests.Entities
{
    [Table("Person")]
    public class Person : Entity<int>, IMustHaveTenant
    {
        protected Person()
        {
        }

        public Person(string name) : this()
        {
            Name = name;
        }

        public virtual string Name { get; set; }

        public string TenantId { get; set; }
    }
}
