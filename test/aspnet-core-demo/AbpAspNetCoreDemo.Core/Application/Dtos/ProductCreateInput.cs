using System.ComponentModel.DataAnnotations;
using Abp.Application.Services.Dto;
using Abp.AutoMapper;
using AbpAspNetCoreDemo.Core.Domain;

namespace AbpAspNetCoreDemo.Core.Application.Dtos
{
    [AutoMap(typeof(Product))]
    public class ProductCreateInput
    {
        [Required]
        [StringLength(200)]
        public string Name { get; set; }

        public float? Price { get; set; }
    }
}