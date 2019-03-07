using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Newtonsoft.Json;
using ContosoPets.DataAccess.Data;
using ContosoPets.DataAccess.Services;
using Swashbuckle.AspNetCore.Swagger;
using Fluent = ContosoPets.DataAccess.Services.Fluent;
using Linq = ContosoPets.DataAccess.Services.Linq;

namespace ContosoPets.Api
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
            if (Configuration["DataAccessSyntax"].Equals("Linq"))
            {
                services.AddScoped<IOrderService, Linq.OrderService>();
            }
            else
            {
                services.AddScoped<IOrderService, Fluent.OrderService>();
            }

            string dbConnection = Configuration.GetConnectionString("ContosoPets");

            services.AddDbContext<ContosoPetsContext>(options =>
                options.UseSqlServer(dbConnection));

            services.AddMvc()
                // https://github.com/aspnet/AspNetCore/issues/3047#issuecomment-433764670
                .AddJsonOptions(options => options.SerializerSettings.ReferenceLoopHandling = ReferenceLoopHandling.Ignore)
                .SetCompatibilityVersion(CompatibilityVersion.Version_2_2);

            services.AddSwaggerGen(config =>
                config.SwaggerDoc("v1", new Info { Title = "My API", Version = "v1" })
            );
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();

            // Enable middleware to serve generated Swagger as a JSON endpoint.
            app.UseSwagger();

            // Enable middleware to serve swagger-ui (HTML, JS, CSS, etc.), 
            // specifying the Swagger JSON endpoint.
            app.UseSwaggerUI(c =>
            {
                c.SwaggerEndpoint("/swagger/v1/swagger.json", "My API V1");
                c.RoutePrefix = string.Empty;
            });

            app.UseMvc();
        }
    }
}
