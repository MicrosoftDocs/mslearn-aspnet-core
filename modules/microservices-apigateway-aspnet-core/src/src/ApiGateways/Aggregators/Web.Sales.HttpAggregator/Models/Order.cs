using System;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models
{
    public class Order
    {
        public int ordernumber {get; set;}
        public DateTime date { get; set; }
        public string status {get; set;}
        public decimal total {get; set;}
            
    }
}
