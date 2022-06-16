using System.Collections.Generic;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models
{
    public class CatalogData
    {
        public int pageIndex {get; set;}
        public int pageSize {get; set;}

        public int count {get; set;}

        public List<CatalogItem> data {get; set;}

    }
}
