using ContosoPets.Ui.Models;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Services
{
    public class ProductService
    {
        private readonly string _route;
        private readonly HttpClient _httpClient;

        public ProductService(
            HttpClient httpClient,
            IConfiguration configuration)
        {
            _httpClient = httpClient;
            _route = configuration["ProductService:ControllerRoute"];
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

        public Task UpdateProduct(Product product) =>
            _httpClient.PutAsJsonAsync($"{_route}/{product.Id}", product);

        public Task CreateProduct(Product product) =>
            _httpClient.PostAsJsonAsync(_route, product);

        public Task DeleteProduct(int productId) =>
            _httpClient.DeleteAsync($"{_route}/{productId}");
    }
}
