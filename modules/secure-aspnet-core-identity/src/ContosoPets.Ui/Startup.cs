using ContosoPets.Ui.Middlewares;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;

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

            services.AddHttpClient<CloudShellService>(config => 
                config.BaseAddress = new Uri(Configuration["CloudShellService:BaseAddress"]));

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

            app.UseCloudShell();
            app.UseStaticFiles();
            app.UseCookiePolicy();
            app.UseMvc();
        }
    }
}