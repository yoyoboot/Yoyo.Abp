using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

using Abp.Domain.Entities;
using Abp.Domain.Entities.Auditing;

namespace Abp.Dapper.Tests.Entities
{
    [Table("Products")]
    public class Product : FullAuditedEntity<int>, IMayHaveTenant
    {
        protected Product()
        {
        }

        public Product(string name) : this()
        {
            Name = name;
        }

        [Required]
        public string Name { get; set; }
        
        public Status Status { get; set; }

        public string TenantId { get; set; }
    }

    public enum Status
    {
        Active,
        Passive
    }
}
