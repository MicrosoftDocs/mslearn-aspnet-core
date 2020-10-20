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

namespace eShopConContainers.WebSPA
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
            RegisterAppInsights(services);

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

            // Add Antiforgery services and configure the header name that angular will use by default.
            services.AddAntiforgery(options => options.HeaderName = "X-XSRF-TOKEN");

            // Add controllers support and add a global AutoValidateAntiforgeryTokenFilter that will make the app check for an Antiforgery token on all "mutating" requests (POST, PUT, DELETE).
            // The AutoValidateAntiforgeryTokenFilter is an internal class registered when we register views, so we need to register controllers and views also.
            services.AddControllersWithViews(options =>
                        options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()))
                    .AddJsonOptions(options => 
                        options.JsonSerializerOptions.PropertyNameCaseInsensitive = true);

            // Setup where the compiled version of our SPA will be, when in production.
            services.AddSpaStaticFiles(configuration => configuration.RootPath = "wwwroot");
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

            // Here, we add Angular default Antiforgery cookie name on first load.
            // https://angular.io/guide/http#security-xsrf-protection
            // This cookie will be read by Angular app and its value will be sent 
            // back to the app as the header configured in .AddAntiforgery().
            app.Use(next => context =>
            {
                string path = context.Request.Path.Value;

                if (string.Equals(path, "/", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(path, "/index.html", StringComparison.OrdinalIgnoreCase))
                {
                    // The request token has to be sent as a JavaScript-readable cookie, 
                    // and Angular uses it by default.
                    var tokens = antiforgery.GetAndStoreTokens(context);
                    context.Response.Cookies.Append("XSRF-TOKEN", tokens.RequestToken,
                        new CookieOptions() { HttpOnly = false });
                }

                return next(context);
            });

            // Seed Data
            WebContextSeed.Seed(app, env, loggerFactory);

            var pathBase = Configuration["PATH_BASE"];

            if (!string.IsNullOrEmpty(pathBase))
            {
                loggerFactory.CreateLogger<Startup>().LogDebug("Using PATH BASE '{pathBase}'", pathBase);
                app.UsePathBase(pathBase);
            }

            app.UseDefaultFiles();
            app.UseStaticFiles();

            // this will make the app to respond with the index.html and the rest of the assets present on the configured folder (at AddSpaStaticFiles() (wwwroot))
            if (!env.IsDevelopment())
            {
                app.UseSpaStaticFiles();
            }
            app.UseRouting();
            app.UseEndpoints(endpoints =>
            {
                // Add the MapFeatureManagement code

                endpoints.MapDefaultControllerRoute();
                endpoints.MapControllers();
                endpoints.MapHealthChecks("/liveness", new HealthCheckOptions
                {
                    Predicate = r => r.Name.Contains("self")
                });
                endpoints.MapHealthChecks("/hc", new HealthCheckOptions()
                {
                    Predicate = _ => true,
                    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
                });
            });

            // Handles all still unattended (by any other middleware) requests by returning the default page of the SPA (wwwroot/index.html).
            app.UseSpa(spa =>
            {
                // To learn more about options for serving an Angular SPA from ASP.NET Core,
                // see https://go.microsoft.com/fwlink/?linkid=864501

                // the root of the angular app. (Where the package.json lives)
                spa.Options.SourcePath = "Client";

                if (env.IsDevelopment())
                { 
                    // use the SpaServices extension method for angular, that will make the application to run "ng serve" for us, when in development.
                    spa.UseAngularCliServer(npmScript: "start");
                }
            });
        }

        private void RegisterAppInsights(IServiceCollection services)
        {
            services.AddApplicationInsightsTelemetry(Configuration);
            services.AddApplicationInsightsKubernetesEnricher();
        }
    }
}
