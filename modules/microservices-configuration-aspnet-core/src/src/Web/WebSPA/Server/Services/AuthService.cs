using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace WebSPA.Server.Services
{
    public class AuthService : IAuthService
    {

        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;

        private readonly string _identityUrl;
        private readonly ILogger<AuthService> _logger;


        public AuthService(ILogger<AuthService> logger,HttpClient httpClient, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            _httpClient = httpClient;

            _identityUrl = $"{_configuration.GetValue<string>("IdentityTokenUrl")}";            
        }

        public async Task<string> GetAccessTokenAsync()
        {
            string access_token = string.Empty;

            try
            {
                var data = new Dictionary<string, string>();

                data.Add("Content-Type", "application/x-www-form-urlencoded");
                data.Add("client_id", "couponapi");
                data.Add("client_secret", "secret");
                data.Add("grant_type", "client_credentials");
                data.Add("scope", "coupon");

                var response = await _httpClient.PostAsync(_identityUrl, new FormUrlEncodedContent(data));

                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadAsStringAsync();
                    access_token =  JsonConvert.DeserializeObject<Dictionary<string, string>>(result)["access_token"];
                }                
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.ToString());
                throw ex;
            }

            return access_token;
        }
    }
}
