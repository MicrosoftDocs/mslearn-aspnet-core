using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using QRCoder;
using System;
using System.Net;
using System.Net.Mime;

namespace ContosoPets.Ui
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.Configure<CookiePolicyOptions>(options =>
            {
                options.CheckConsentNeeded = context => true;
                options.MinimumSameSitePolicy = SameSiteMode.None;
            });

            IConfigurationSection cpServicesConfig = Configuration.GetSection("ContosoPetsServices");

            services.AddHttpClient<OrderService>(config => {
               config.BaseAddress = new Uri(
                   $"{cpServicesConfig["BaseAddress"]}{cpServicesConfig["Routes:Orders"]}");
               config.DefaultRequestHeaders.Add(
                   HttpRequestHeader.Accept.ToString(),
                   MediaTypeNames.Application.Json.ToString());
            });

            services.AddHttpClient<ProductService>(config => {
                config.BaseAddress = new Uri(
                    $"{cpServicesConfig["BaseAddress"]}{cpServicesConfig["Routes:Products"]}");
                config.DefaultRequestHeaders.Add(
                    HttpRequestHeader.Accept.ToString(),
                    MediaTypeNames.Application.Json.ToString());
            });

            services.AddSingleton(new QRCodeService(new QRCodeGenerator()));
            services.AddSingleton<AdminRegistrationTokenService>();
            
            // Add call to AddAuthorization

            services.AddMvc()
                .SetCompatibilityVersion(CompatibilityVersion.Version_2_2);

            services.AddAntiforgery(options => options.HeaderName = "X-CSRF-TOKEN");
        }

        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                app.UseHsts();
            }

            app.UseStaticFiles();
            app.UseCookiePolicy();
            // Add the app.UseAuthentication code
            app.UseMvc();
        }
    }
}
