using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace WebCouponStatus.Services
{
    public class CouponService : ICouponService
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly ILogger<CouponService> _logger;

        private readonly string _remoteServiceBaseUrl;

        public CouponService(HttpClient httpClient, ILogger<CouponService> logger, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;

            _remoteServiceBaseUrl = $"{_configuration.GetValue<string>("CouponUrl")}/api/v1/coupon/";
        }

        public async Task<List<CouponDto>> GetAllAvailableCouponsAsync()
        {
            var responseString = await _httpClient.GetStringAsync(_remoteServiceBaseUrl);

            var allCoupons = JsonConvert.DeserializeObject<List<CouponDto>>(responseString);

            return allCoupons;
        }
    }
}
