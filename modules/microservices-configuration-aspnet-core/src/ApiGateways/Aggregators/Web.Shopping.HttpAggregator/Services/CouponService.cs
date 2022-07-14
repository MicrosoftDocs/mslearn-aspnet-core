using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Config;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Services
{
    public class CouponService : ICouponService
    {
        public readonly HttpClient _httpClient;
        private readonly UrlsConfig _urls;
        private readonly ILogger<CouponService> _logger;

        public CouponService(HttpClient httpClient, IOptions<UrlsConfig> config, ILogger<CouponService> logger)
        {
            _urls = config.Value;
            _httpClient = httpClient;
            _logger = logger;
        }

        public async Task<HttpResponseMessage> CheckCouponByCodeNumberAsync(string codeNumber)
        {
            _logger.LogInformation("----- WebAggregator --> Coupon-API: {codeNumber}", codeNumber);

            var url = new Uri($"{_urls.Coupon}/api/v1/coupon/{codeNumber.Trim().ToUpper()}");

            var response = await _httpClient.GetAsync(url);

            _logger.LogInformation("----- WebAggregator <-- Coupon-API: {@response}", response);

            return response;
        }

        public async Task<HttpResponseMessage> GetAllAvailableCouponsAsync()
        {
            _logger.LogInformation("----- WebAggregator --> Coupon-API: Requested all available coupon");

            var url = new Uri($"{_urls.Coupon}/api/v1/coupon");

            var response = await _httpClient.GetAsync(url);

            _logger.LogInformation("----- WebAggregator <-- Coupon-API [Available Coupon]: {@response}", response);

            return response;
        }
    }
}
