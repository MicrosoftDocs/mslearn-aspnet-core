using Microsoft.AspNetCore.Mvc;

namespace Microsoft.eShopOnContainers.Web.Sales.HttpAggregator.Controllers
{    
    public class HomeController : Controller
    {        
        public IActionResult Index()
        {
            return new RedirectResult("~/swagger");
        }
    }
}
