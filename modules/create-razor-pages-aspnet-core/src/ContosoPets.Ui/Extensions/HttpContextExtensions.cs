using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Http;

namespace ContosoPets.Ui.Extensions
{
    public static class HttpContextExtensions
    {
        public static string GetAntiforgeryTokenForJs(this HttpContext httpContext)
        {
            IAntiforgery antiforgery = (IAntiforgery)httpContext.RequestServices.GetService(typeof(IAntiforgery));
            var tokenSet = antiforgery.GetAndStoreTokens(httpContext);
            return tokenSet.RequestToken;
        }
    }
}
