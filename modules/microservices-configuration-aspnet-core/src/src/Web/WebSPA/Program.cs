using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Serilog;
using System;
using System.IO;
using System.Threading.Tasks;

namespace eShopOnContainers.WebSPA
{
    public class Program
    {
        public static Task Main(string[] args) =>
            CreateHostBuilder(args).Build().RunAsync();

        private static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder => webBuilder.UseStartup<Startup>())
                .UseContentRoot(Directory.GetCurrentDirectory())
                // Add the AddAzureAppConfiguration code
                .ConfigureLogging((hostingContext, logBuilder) =>
                {
                    logBuilder.AddConfiguration(hostingContext.Configuration.GetSection("Logging"));
                    logBuilder.AddConsole();
                    logBuilder.AddDebug();
                    logBuilder.AddAzureWebAppDiagnostics();
                })
                .UseSerilog((builderContext, config) =>
                {
                    config
                        .MinimumLevel.Information()
                        .Enrich.FromLogContext()
                        .WriteTo.Seq("http://seq")
                        .ReadFrom.Configuration(builderContext.Configuration)
                        .WriteTo.Console();
                });
    }
}
