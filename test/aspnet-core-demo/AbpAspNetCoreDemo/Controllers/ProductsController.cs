using AbpAspNetCoreDemo.Core.Domain;
using Abp.AspNetCore.OData.Controllers;
using Abp.Dependency;
using Abp.Domain.Repositories;

namespace AbpAspNetCoreDemo.Controllers
{
    public class ProductsController : AbpODataEntityController<Product, int>, ITransientDependency
    {
        public ProductsController(IRepository<Product, int> repository) : base(repository)
        {
            GetPermissionName = "GetProductPermission";
            GetAllPermissionName = "GetAllProductsPermission";
            CreatePermissionName = "CreateProductPermission";
            UpdatePermissionName = "UpdateProductPermission";
            DeletePermissionName = "DeleteProductPermission";
        }
    }
}
