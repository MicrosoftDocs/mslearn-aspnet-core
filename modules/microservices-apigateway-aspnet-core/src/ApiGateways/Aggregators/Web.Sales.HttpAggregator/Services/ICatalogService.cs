using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Services
{
    public interface ICatalogService
    {
        Task<List<CatalogItem>> GetCatalogItemAsync();
                
        Task<List<CatalogBrand>> GetCatalogBrandAsync();
    }
}
