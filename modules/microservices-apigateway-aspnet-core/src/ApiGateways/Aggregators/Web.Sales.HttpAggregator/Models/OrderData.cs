using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models
{
    public class OrderData
    {
        public int OrderNumber { get; set; }
        public DateTime Date { get; set; }
        public string Status { get; set; }
        public decimal Total { get; set; }
        public string Description { get; set; }
        public string City { get; set; }
        public string Street { get; set; }
        public string State { get; set; }
        public string Country { get; set; }
        public string ZipCode { get; set; }
        public List<OrderItemData> OrderItems { get; set; }
    }
}
