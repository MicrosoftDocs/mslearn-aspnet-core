﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models
{
    public class OrderItemData
    {
        public string ProductName { get; set; }
        public decimal UnitPrice { get; set; }        
        public int Units { get; set; }
        public string PictureUrl { get; set; }
    }
}
