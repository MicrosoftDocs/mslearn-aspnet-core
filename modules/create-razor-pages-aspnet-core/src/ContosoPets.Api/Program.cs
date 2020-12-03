using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ContosoPets.Api.Data;
using ContosoPets.Api;

CreateHostBuilder(args).Build().SeedDatabase().Run();

static IHostBuilder CreateHostBuilder(string[] args) =>
    Host.CreateDefaultBuilder(args)
        .ConfigureWebHostDefaults(webBuilder => webBuilder.UseStartup<Startup>());

static class IHostExtensions
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