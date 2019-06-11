using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;

namespace ContosoPets.Ui.Middlewares
{
    public static class CloudShellMiddlewareExtensions
    {
        public static IApplicationBuilder UseCloudShell(
            this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<CloudShellMiddleware>();
        }
    }
}