using Abp.AspNetCore.OData.Controllers;
using Abp.Dependency;
using Abp.Domain.Repositories;
using Abp.ObjectMapping;
using AbpAspNetCoreDemo.Core.Application.Dtos;
using AbpAspNetCoreDemo.Core.Domain;

namespace AbpAspNetCoreDemo.Controllers
{
    public class ProductsDtoController : AbpODataDtoController<Product, ProductDto, ProductCreateInput, long>, ITransientDependency
    {
        public ProductsDtoController(IRepository<Product, long> repository, IObjectMapper objectMapper) : base(repository, objectMapper)
        {
            GetPermissionName = "GetProductPermission";
            GetAllPermissionName = "GetAllProductsPermission";
            CreatePermissionName = "CreateProductPermission";
            UpdatePermissionName = "UpdateProductPermission";
            DeletePermissionName = "DeleteProductPermission";
        }
    }
}
