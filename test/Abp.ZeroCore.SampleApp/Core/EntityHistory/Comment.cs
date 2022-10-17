using Abp.Auditing;
using Abp.Domain.Entities;

namespace Abp.ZeroCore.SampleApp.Core.EntityHistory
{
    [Audited]
    public class Comment : Entity<int>
    {
        public Post Post { get; set; }

        public string Content { get; set; }
    }
}
