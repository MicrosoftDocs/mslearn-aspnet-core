using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using QRCoder;

namespace ContosoPets.Ui
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
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
               config.DefaultRequestHeaders.Add("Accept", "application/json");
            });

            services.AddHttpClient<ProductService>(config => {
                config.BaseAddress = new Uri(
                    $"{cpServicesConfig["BaseAddress"]}{cpServicesConfig["Routes:Products"]}");
                config.DefaultRequestHeaders.Add("Accept", "application/json");
            });

            services.AddSingleton(new QRCodeService(new QRCodeGenerator()));
            services.AddSingleton<AdminRegistrationTokenService>();

            services.AddAntiforgery(options => options.HeaderName = "X-CSRF-TOKEN");
            services.AddRazorPages();
            services.AddControllers();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseStaticFiles();
            app.UseCookiePolicy();

            app.UseRouting();

            // Add the app.UseAuthentication code
            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.MapRazorPages();
            });
        }
    }
}
