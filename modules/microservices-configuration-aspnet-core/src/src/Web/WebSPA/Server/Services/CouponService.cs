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
        private readonly ILogger<AuthService> _logger;
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;

        private readonly string _remoteServiceBaseUrl;

        private readonly IAuthService _authService;
        

        public CouponService(ILogger<AuthService> logger, HttpClient httpClient, IConfiguration configuration, IAuthService authService)
        {
            _logger = logger;
            _httpClient = httpClient;
            _configuration = configuration;

            _remoteServiceBaseUrl = $"{_configuration.GetValue<string>("purchaseUrl")}/cp/api/v1/coupon/";

            _authService = authService;

        }

        public async Task<List<Coupon>> GetAllAvailableCouponsAsync()
        {
            List<Coupon> allCoupons = new List<Coupon>();

            try
            {
                var token = await _authService.GetAccessTokenAsync();

                _logger.LogInformation("Token : " + token);

                if (!String.IsNullOrEmpty(token))
                {
                    _httpClient.DefaultRequestHeaders.Add("Authorization", "Bearer " + token);

                    var responseString = await _httpClient.GetStringAsync(_remoteServiceBaseUrl);

                    allCoupons = JsonConvert.DeserializeObject<List<Coupon>>(responseString);                    
                }
                
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.ToString());
                throw ex;
            }

            return allCoupons;
        }
    }
}
