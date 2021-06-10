using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models;
using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Services;
using Newtonsoft.Json;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Controllers
{
    [Route("api/v1/[controller]")]
    [Authorize(Roles = "Admin")]
    [ApiController]
    public class SalesController : ControllerBase
    {
        private readonly ICatalogService _catalog;
        private readonly IOrderingService _ordering;

        private readonly ILogger<SalesController> _logger;

        public SalesController(ICatalogService catalogService, IOrderingService orderingService, ILogger<SalesController> logger)
        {
            _catalog = catalogService;
            _ordering = orderingService;
            _logger = logger;
        }

        [HttpGet]
        [ProducesResponseType(typeof(SalesDto), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<List<SalesDto>>> GetSalesOfTodayByBrand()
        {
            _logger.LogInformation("----- SalesController --> GetTotalSalesAsync()");

            try
            {
                // All catalog items
                var catalogItems = await _catalog.GetCatalogItemAsync();

                // All catalog brands
                var catalogBrands = await _catalog.GetCatalogBrandAsync();

                // All orders
                var orderItems = await _ordering.GetOrdersAsync();

                // Fetch processed sales data
                var salesData = await this.GetSalesData(catalogItems, catalogBrands, orderItems);

                return salesData;
            }
            catch (System.Exception ex)
            {
                throw ex;
            }
        }

        private async Task<List<SalesDto>> GetSalesData(List<CatalogItem> catalogItems, List<CatalogBrand> catalogBrands, List<Order> listOfOrders)
        {
            _logger.LogInformation("----- Processing sales data <-- GetSalesData() ");

            var salesDataItem = new List<SalesData>();

            // Filter all the orders based on the present day and which are processed
            var allOrdersOfPresentDay = listOfOrders.Where(o => o.date.Day == DateTime.Today.Day && o.status == "Paid");

            _logger.LogInformation($"----- allOrdersOfPresentDay : {JsonConvert.SerializeObject(allOrdersOfPresentDay)}");

            foreach (var eachOrder in allOrdersOfPresentDay)
            {
                // Fetch each order details based on order number
                var specificOrderItem = await _ordering.GetOrderDetailsAsync(eachOrder.ordernumber);

                if (specificOrderItem != null &&
                    specificOrderItem.OrderItems != null && specificOrderItem.OrderItems.Count() > 0)
                {
                    // Calculate each product unit of sale
                    foreach (var eachProduct in specificOrderItem.OrderItems)
                    {
                        // Filter catalog item
                        var catalogItemObj = catalogItems.Find(catalogItem => catalogItem.name == eachProduct.ProductName);

                        // Populate sales data
                        salesDataItem.Add(new SalesData()   
                        {
                            CatalogBrandId = catalogItemObj.catalogBrandId,
                            CatalogBrandName = catalogBrands.Find(catalogBrand => catalogBrand.Id == catalogItemObj.catalogBrandId).Brand, // Fetch the brand name based on it's id
                            TotalUnitOfSoldItems = eachProduct.Units
                        });
                    }
                }

            }
            
            // Aggregate the unit of sales based on the Brand name
            var groupedSalesData = salesDataItem.GroupBy(catalogBrand => catalogBrand.CatalogBrandName)
                                                .Select(
                                                    catalogBrand => new SalesDto() {      
                                                        BrandName = catalogBrand.Key,                                                                                                
                                                        TotalSales = catalogBrand.Sum(unit => unit.TotalUnitOfSoldItems),
                                                    }).ToList();

            _logger.LogInformation($"----- groupedSalesData : {JsonConvert.SerializeObject(groupedSalesData)}");

            return groupedSalesData;
        }
    }
}
