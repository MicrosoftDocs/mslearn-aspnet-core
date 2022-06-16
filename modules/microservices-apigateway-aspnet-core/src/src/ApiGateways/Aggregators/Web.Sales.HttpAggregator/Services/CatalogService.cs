using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Config;
using Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using System;
using System.Linq;
using Newtonsoft.Json;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Services
{
    public class CatalogService : ICatalogService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<CatalogService> _logger;

        private readonly UrlsConfig _urls;

        public CatalogService(HttpClient httpClient, ILogger<CatalogService> logger, IOptions<UrlsConfig> config)
        {
            _httpClient = httpClient;
            _logger = logger;
            _urls = config.Value;        
        }

        public async Task<List<CatalogBrand>> GetCatalogBrandAsync()
        {
            _logger.LogInformation("----- WebSalesAggregator --> GetCatalogBrandAsync()");

            var url = new Uri($"{_urls.Catalog}/api/v1/Catalog/catalogbrands");

            _logger.LogInformation($"----- requested url --> {url}");

            var response = await _httpClient.GetAsync(url);
                        
            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();

                _logger.LogInformation("----- WebSalesAggregator <-- all brands: {@content}", content);


                List<CatalogBrand> catalogBrandItems = JsonConvert.DeserializeObject<List<CatalogBrand>>(content);

                return catalogBrandItems;
            }            

            return null;
        }        


        public async Task<List<CatalogItem>> GetCatalogItemAsync()
        {

            _logger.LogInformation("----- WebSalesAggregator --> GetCatalogItemsAsync()");

            var url = new Uri($"{_urls.Catalog}/api/v1/Catalog/items?pageSize=100");

            _logger.LogInformation($"----- requested url --> {url}");

            var response = await _httpClient.GetAsync(url);            

            if (response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                
                _logger.LogInformation("----- WebSalesAggregator <-- all catalog items: {@content}", content);

                var catalogData = JsonConvert.DeserializeObject<CatalogData>(content);

                return catalogData.data;
            }            

            return null;
        }
    }
}
