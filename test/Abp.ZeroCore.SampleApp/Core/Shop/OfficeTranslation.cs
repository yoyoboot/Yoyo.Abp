using Abp.Domain.Entities;

namespace Abp.ZeroCore.SampleApp.Core.Shop;

public class OfficeTranslation : Entity<string>, IEntityTranslation<Office, string>
{
    public virtual string Name { get; set; }

    public string Language { get; set; }

    public Office Core { get; set; }

    public string CoreId { get; set; }
}
