using Microsoft.eShopOnContainers.Services.Basket.API.Model;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Microsoft.eShopOnContainers.Services.Basket.API.Infrastructure.Repositories
{
    public class InMemoryBasketRepository : IBasketRepository
    {
        private readonly ILogger<InMemoryBasketRepository> _logger;
        private Dictionary<string, string> _basketMapData;

        public InMemoryBasketRepository(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<InMemoryBasketRepository>();
            _basketMapData = new Dictionary<string, string>();
        }

#pragma warning disable 1998
        public async Task<bool> DeleteBasketAsync(string id)
        {
            return _basketMapData.Remove(id);
        }

        public async Task<CustomerBasket> GetBasketAsync(string customerId)
        {
            if (_basketMapData.ContainsKey(customerId))
            {
                var data = _basketMapData.GetValueOrDefault(customerId);

                return JsonConvert.DeserializeObject<CustomerBasket>(data);
            }

            return null;
        }
#pragma warning restore

        public IEnumerable<string> GetUsers()
        {
            return _basketMapData.Keys.ToList();
        }

        public async Task<CustomerBasket> UpdateBasketAsync(CustomerBasket basket)
        {
            if (basket == null)
            {
                _logger.LogInformation("Basket is empty.");
                return null;
            }

            if (_basketMapData.ContainsKey(basket.BuyerId))
            {
                _logger.LogInformation("BuyerId is present. So updating the basket details.");
                _basketMapData[basket.BuyerId] = JsonConvert.SerializeObject(basket);
            }
            else
            {
                _logger.LogInformation("BuyerId is not present. So adding it new.");
                _basketMapData.Add(basket.BuyerId, JsonConvert.SerializeObject(basket));
            }

            _logger.LogInformation("Basket item has been captured in memory.");

            return await GetBasketAsync(basket.BuyerId);
        }
    }
}