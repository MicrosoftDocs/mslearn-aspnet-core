using ContosoPets.Ui.Services;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;

namespace ContosoPets.Ui
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateWebHostBuilder(args).Build().Run();
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .UseUrls($"http://*:{(int)CloudShellPorts.Port8000}")
                .UseStartup<Startup>();
    }
}
