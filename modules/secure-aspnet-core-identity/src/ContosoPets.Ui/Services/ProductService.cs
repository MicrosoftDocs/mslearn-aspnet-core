using ContosoPets.Ui.Models;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Services
{
    public class ProductService
    {
        private readonly string _route;
        private readonly HttpClient _httpClient;

        public ProductService(HttpClient httpClient)
        {
            _httpClient = httpClient;
            _route = httpClient.BaseAddress.AbsoluteUri;
        }

        public async Task<IEnumerable<Product>> GetProducts()
        {
            var response = await _httpClient.GetAsync(_route);
            response.EnsureSuccessStatusCode();

            var products = await response.Content.ReadAsAsync<IEnumerable<Product>>();

            return products;
        }

        public async Task<Product> GetProductById(int productId)
        {
            var response = await _httpClient.GetAsync($"{_route}/{productId}");
            response.EnsureSuccessStatusCode();

            var product = await response.Content.ReadAsAsync<Product>();

            return product;
        }

        public async Task UpdateProduct(Product product) =>
            await _httpClient.PutAsJsonAsync<Product>($"{_route}/{product.Id}", product);

        public async Task CreateProduct(Product product) =>
            await _httpClient.PostAsJsonAsync<Product>(_route, product);

        public async Task DeleteProduct(int productId) =>
            await _httpClient.DeleteAsync($"{_route}/{productId}");
    }
}
