using ContosoPets.Ui.Models;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Services
{
    public class OrderService
    {
        private readonly string _route;
        private readonly HttpClient _httpClient;

        public OrderService(HttpClient httpClient)
        {
            _httpClient = httpClient;
            _route = httpClient.BaseAddress.AbsoluteUri;
        }

        public async Task<IEnumerable<Order>> GetOrders()
        {
            var response = await _httpClient.GetAsync(_route);
            response.EnsureSuccessStatusCode();

            var orders = await response.Content.ReadAsAsync<IEnumerable<Order>>();

            return orders;
        }
    }
}
