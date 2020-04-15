using System;
using System.Net.Mime;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Net.Http.Headers;
using QRCoder;
using Http = Microsoft.AspNetCore.Http;

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
                options.MinimumSameSitePolicy = Http.SameSiteMode.None;
            });

            IConfigurationSection cpServicesConfig = Configuration.GetSection("ContosoPetsServices");

            services.AddHttpClient<ProductService>(config => {
                config.BaseAddress = new Uri(
                    $"{cpServicesConfig["BaseAddress"]}{cpServicesConfig["Routes:Products"]}");
                config.DefaultRequestHeaders.Add(HeaderNames.Accept, MediaTypeNames.Application.Json);
            });

            services.AddSingleton(new QRCodeService(new QRCodeGenerator()));
            services.AddSingleton<AdminRegistrationTokenService>();

            // Add call to AddAuthorization

            services.AddAntiforgery(options => options.HeaderName = "X-CSRF-TOKEN");
            services.AddRazorPages();
            services.AddControllers();
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
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
