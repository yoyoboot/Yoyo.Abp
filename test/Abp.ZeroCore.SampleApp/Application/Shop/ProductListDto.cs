using Abp.Application.Services.Dto;

namespace Abp.ZeroCore.SampleApp.Application.Shop
{
    public class ProductListDto : EntityDto<int>
    {
        public decimal Price { get; set; }

        public string Name { get; set; }

        public string Language { get; set; }
    }
}
