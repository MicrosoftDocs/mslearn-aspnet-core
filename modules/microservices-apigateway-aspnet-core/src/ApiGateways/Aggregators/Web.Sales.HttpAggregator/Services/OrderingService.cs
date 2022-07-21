using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Config;
using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Services
{
    public class OrderingService : IOrderingService
    {
        private readonly UrlsConfig _urls;
        private readonly ILogger<OrderingService> _logger;
        public readonly HttpClient _httpClient;

        public OrderingService(HttpClient httpClient, IOptions<UrlsConfig> config, ILogger<OrderingService> logger)
        {
            _urls = config.Value;
            _httpClient = httpClient;
            _logger = logger;
        }

        public async Task<List<Order>> GetOrdersAsync()
        {
            _logger.LogInformation("----- WebSalesAggregator --> GetOrdersAsync()");

            var url = new Uri($"{_urls.Orders}/api/v1/Orders");

            _logger.LogInformation($"----- requested url --> {url}");

            var response = await _httpClient.GetAsync(url);

            _logger.LogInformation("----- GetOrdersAsync response <-- all order items: {@response}", response);
            
            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();

                _logger.LogInformation("----- WebSalesAggregator <-- all order items: {@content}", content);

                var orderData = JsonConvert.DeserializeObject<List<Order>>(content);

                return orderData;
            }

            return null;
        }
        
        public async Task<OrderData> GetOrderDetailsAsync(int orderId)
        {

            _logger.LogInformation("----- WebSalesAggregator --> GetOrderDetailsAsync()");

            var url = new Uri($"{_urls.Orders}/api/v1/Orders/{orderId}");

            _logger.LogInformation($"----- requested url --> {url}");

            var response = await _httpClient.GetAsync(url);

            _logger.LogInformation("----- GetOrderDetailsAsync response <-- order details: {@response}", response);

            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();

                _logger.LogInformation("----- WebSalesAggregator <-- order details: {@content}", content);

                var orderData = JsonConvert.DeserializeObject<OrderData>(content);

                return orderData;
            }

            return null;
        }
    }
}
