using ContosoPets.Ui.Models;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Services
{
    public class CloudShellService
    {
        private readonly string _route;
        private readonly HttpClient _httpClient;

        public CloudShellService(HttpClient httpClient)
        {
            _httpClient = httpClient;
            _route = httpClient.BaseAddress.AbsoluteUri;
        }

        public async Task<Uri> OpenPort(CloudShellPorts portNumber)
        {
            var response = await _httpClient.PostAsync($"{_route}/{(int)portNumber}", null);
            return new Uri(JObject.Parse(await response.Content.ReadAsStringAsync())["url"].Value<string>());
        }
    }

    public enum CloudShellPorts {
        Port8000 = 8000,
        Port8001 = 8001,
        Port8002 = 8002
    }
}