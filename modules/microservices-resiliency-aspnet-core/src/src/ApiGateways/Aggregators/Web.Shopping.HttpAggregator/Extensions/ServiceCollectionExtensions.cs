using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http;
using Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Config;
using Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Filters.Basket.API.Infrastructure.Filters;
using Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Infrastructure;
using Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;
using Newtonsoft.Json.Converters;
using Serilog;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
// Add the using statements

namespace Microsoft.eShopOnContainers.Web.Shopping.HttpAggregator.Extensions
{
    public static class ServiceCollectionExtensions
    {
        // Add the GetRetryPolicy method

        // Add the GetCircuitBreakerPolicy method

        public static IServiceCollection AddApplicationServices(this IServiceCollection services)
        {
            //register delegating handlers
            services.AddTransient<HttpClientAuthorizationDelegatingHandler>();
            services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();

            //register HTTP services
            services.AddHttpClient<ICouponService, CouponService>()
                .AddHttpMessageHandler<HttpClientAuthorizationDelegatingHandler>();

            services.AddHttpClient<IBasketService, BasketService>()
                .AddHttpMessageHandler<HttpClientAuthorizationDelegatingHandler>();

            services.AddHttpClient<ICatalogService, CatalogService>();

            services.AddHttpClient<IOrderApiClient, OrderApiClient>()
                .AddHttpMessageHandler<HttpClientAuthorizationDelegatingHandler>();

            services.AddHttpClient<IOrderingService, OrderingService>()
                .AddHttpMessageHandler<HttpClientAuthorizationDelegatingHandler>();

            return services;
        }        

        public static IServiceCollection AddCustomAuthentication(this IServiceCollection services, IConfiguration configuration)
        {
            JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Remove("sub");

            var identityUrl = configuration.GetValue<string>("urls:identity");
            services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;

            })
            .AddJwtBearer(options =>
            {
                options.Authority = identityUrl;
                options.RequireHttpsMetadata = false;
                options.Audience = "webshoppingagg";
            });

            return services;
        }

        public static IServiceCollection AddCustomMvc(this IServiceCollection services, IConfiguration configuration)
        {
            services.AddOptions();
            services.Configure<UrlsConfig>(configuration.GetSection("urls"));
            services.AddControllers()
                    .AddNewtonsoftJson(options => 
                        options.SerializerSettings.Converters.Add(new StringEnumConverter()));

            services.AddSwaggerGen(options =>
            {
                options.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "Shopping Aggregator for Web Clients",
                    Version = "v1",
                    Description = "Shopping Aggregator for Web Clients",
                });

                options.AddSecurityDefinition("oauth2", new OpenApiSecurityScheme
                {
                    Type = SecuritySchemeType.OAuth2,
                    Flows = new OpenApiOAuthFlows
                    {
                        Implicit = new OpenApiOAuthFlow
                        {
                            AuthorizationUrl = new Uri($"{configuration.GetValue<string>("IdentityUrlExternal")}/connect/authorize"),
                            TokenUrl = new Uri($"{configuration.GetValue<string>("IdentityUrlExternal")}/connect/token"),
                            Scopes = new Dictionary<string, string>()
                            {
                                { "webshoppingagg", "Shopping Aggregator for Web Clients" }
                            },
                        }
                    }
                });

                options.OperationFilter<AuthorizeCheckOperationFilter>();
            });

            services.AddSwaggerGenNewtonsoftSupport();
            services.AddCors(options =>
            {
                options.AddPolicy("CorsPolicy", builder => 
                    builder.SetIsOriginAllowed((host) => true)
                        .AllowAnyMethod()
                        .AllowAnyHeader()
                        .AllowCredentials());
            });

            return services;
        }
    }
}
