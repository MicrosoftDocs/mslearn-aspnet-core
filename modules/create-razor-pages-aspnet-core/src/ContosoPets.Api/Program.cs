using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ContosoPets.Api.Data;
using System.Threading.Tasks;

namespace ContosoPets.Api
{
    public class Program
    {
        static Task Main(string[] args) =>
            CreateHostBuilder(args).Build().SeedDatabase().RunAsync();

        static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder => webBuilder.UseStartup<Startup>());
    }

    public static class IHostExtensions
    {
        public static IHost SeedDatabase(this IHost host)
        {
            var scopeFactory = host.Services.GetRequiredService<IServiceScopeFactory>();
            using var scope = scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<ContosoPetsContext>();

            if (context.Database.EnsureCreated())
                SeedData.Initialize(context);

            return host;
        }
    }
}