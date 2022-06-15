namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models
{
    public class CatalogItem
    {
        public int id { get; set; }

        public string name { get; set; }

        public string description { get; set; }

        public decimal price { get; set; }

        public string pictureUri { get; set; }

        public int catalogBrandId {get; set;}

        public int availableStock {get; set;}

    }
}
