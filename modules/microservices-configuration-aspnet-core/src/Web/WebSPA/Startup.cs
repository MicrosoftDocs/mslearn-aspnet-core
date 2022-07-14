using eShopOnContainers.WebSPA;
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SpaServices.AngularCli;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
//using Microsoft.FeatureManagement;
using StackExchange.Redis;
using System;
using WebSPA.Infrastructure;
using WebSPA.Server.Services;

namespace eShopOnContainers.WebSPA
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public Startup()
        {
            var localPath = new Uri(Configuration["ASPNETCORE_URLS"])?.LocalPath ?? "/";
            Configuration["BaseUrl"] = localPath;
        }

        public void ConfigureServices(IServiceCollection services)
        {
            // Add the AddFeatureManagement code

            services
                .AddHealthChecks()
                .AddCheck("self", () => HealthCheckResult.Healthy())
                .AddUrlGroup(new Uri(Configuration["IdentityUrlHC"]), 
                    name: "identityapi-check", 
                    tags: new string[] { "identityapi" });

            services.Configure<AppSettings>(Configuration);

            if (Configuration.GetValue<string>("IsClusterEnv") == bool.TrueString)
            {
                services.AddDataProtection(options =>
                    options.ApplicationDiscriminator = "eshop.webspa")
                .PersistKeysToStackExchangeRedis(ConnectionMultiplexer.Connect(
                    Configuration["DPConnectionString"]), "DataProtection-Keys");
            }

            services.AddAntiforgery(options => options.HeaderName = "X-XSRF-TOKEN");
            services.AddControllersWithViews(options =>
                        options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()))
                    .AddJsonOptions(options => 
                        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true);
            services.AddSpaStaticFiles(configuration => configuration.RootPath = "wwwroot");
            
            services.AddControllersWithViews();
            services.AddHttpClient<ICouponService, CouponService>();
        }

        public void Configure(IApplicationBuilder app, 
            IWebHostEnvironment env, 
            ILoggerFactory loggerFactory, 
            IAntiforgery antiforgery)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            // Add the UseAzureAppConfiguration code

            app.Use(next => context =>
            {
                string path = context.Request.Path.Value;

                if (string.Equals(path, "/", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(path, "/index.html", StringComparison.OrdinalIgnoreCase))
                {
                    var tokens = antiforgery.GetAndStoreTokens(context);
                    context.Response.Cookies.Append("XSRF-TOKEN", tokens.RequestToken,
                        new CookieOptions() { HttpOnly = false });
                }

                return next(context);
            });

            WebContextSeed.Seed(app, env, loggerFactory);

            var pathBase = Configuration["PATH_BASE"];

            if (!string.IsNullOrEmpty(pathBase))
            {
                loggerFactory.CreateLogger<Startup>().LogDebug("Using PATH BASE '{pathBase}'", pathBase);
                app.UsePathBase(pathBase);
            }

            app.UseDefaultFiles();
            app.UseStaticFiles();
            if (!env.IsDevelopment())
            {
                app.UseSpaStaticFiles();
            }
            app.UseRouting();
            app.UseEndpoints(endpoints =>
            {
                // Add the MapFeatureManagement code

                endpoints.MapControllerRoute(
                   name: "CouponStatus",
                   pattern: "{controller=CouponStatus}/{action=Index}/{id?}");

                endpoints.MapDefaultControllerRoute();
                endpoints.MapControllers();
                endpoints.MapHealthChecks("/liveness", new HealthCheckOptions
                {
                    Predicate = r => r.Name.Contains("self")
                });
                endpoints.MapHealthChecks("/hc", new HealthCheckOptions
                {
                    Predicate = _ => true,
                    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
                });
            });

            app.UseSpa(spa =>
            {
                spa.Options.SourcePath = "Client";

                if (env.IsDevelopment())
                { 
                    spa.UseAngularCliServer(npmScript: "start");
                }
            });
        }
    }
}
