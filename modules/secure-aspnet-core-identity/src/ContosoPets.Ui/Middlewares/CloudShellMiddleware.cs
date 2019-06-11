using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Http;
using System;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Middlewares
{
    public class CloudShellMiddleware
    {
        private readonly CloudShellService _cloudShellService;
        private readonly RequestDelegate _next;
        private Uri _proxyUri;
        private readonly bool _isRunningInCloudShell;
        private const string CLOUD_SHELL_UA = "AZURE_HTTP_USER_AGENT";
        private readonly Task _openPort;

        public CloudShellMiddleware(RequestDelegate next,
                                    CloudShellService cloudShellService)
        {
            _isRunningInCloudShell = Environment.GetEnvironmentVariables().Contains(CLOUD_SHELL_UA) &&
                Environment.GetEnvironmentVariable(CLOUD_SHELL_UA).Contains("cloud-shell");

            _next = next;
            _cloudShellService = cloudShellService;

            _openPort = MapPort();
        }

        private async Task MapPort()
        {
            if(_isRunningInCloudShell)
            {
                _proxyUri = await _cloudShellService.OpenPort(CloudShellPorts.Port8000);
            }
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (_isRunningInCloudShell)
            {
                await _openPort;
                Uri referrer = context.Request.GetTypedHeaders().Referer;
                if (referrer != null && referrer.ToString().Contains(_proxyUri.ToString()))
                {
                    context.Request.PathBase = _proxyUri.AbsolutePath;
                }

            }
            // Call the next delegate/middleware in the pipeline
            await _next(context);
        }
    }
}