using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using WebSPA.ViewModels;

namespace WebSPA.Server.Services
{
    public class CouponService : ICouponService
    {
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly string _remoteServiceBaseUrl;
        private readonly ILogger<CouponService> _logger;

        public CouponService(HttpClient httpClient, IConfiguration configuration, ILogger<CouponService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
            _remoteServiceBaseUrl = $"{_configuration.GetValue<string>("purchaseUrl")}/cp/api/v1/coupon/";
        }

        public async Task<List<Coupon>> GetAllAvailableCouponsAsync()
        {
            var allCoupons = new List<Coupon>();

            try
            {
                _logger.LogInformation(_remoteServiceBaseUrl);
                var responseString = await _httpClient.GetStringAsync(_remoteServiceBaseUrl);
                allCoupons = JsonConvert.DeserializeObject<List<Coupon>>(responseString);                    
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, ex.Message);
                throw ex;
            }

            return allCoupons;
        }
    }
}
