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

        // Add the GetSalesOfTodayByBrand code

        // Add the GetSalesData code
    }
}
