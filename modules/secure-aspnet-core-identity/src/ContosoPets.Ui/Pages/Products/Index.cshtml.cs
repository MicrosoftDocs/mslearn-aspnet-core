using ContosoPets.Ui.Extensions;
using ContosoPets.Ui.Models;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Linq;
//using Microsoft.AspNetCore.Authorization;

namespace ContosoPets.Ui.Pages.Products
{
    // Add [Authorize] attribute
    public class IndexModel : PageModel
    {
        private readonly ProductService _productService;

        public string AntiforgeryToken => HttpContext.GetAntiforgeryTokenForJs();
        public IEnumerable<Product> Products { get; private set; } = new List<Product>();
        // Add IsAdmin property

        public IndexModel(ProductService productService)
        {
            _productService = productService;
        }

        public async Task OnGet() =>
            Products = await _productService.GetProducts();
    
        public async Task<IActionResult> OnDelete(int productId)
        {
            // Add IsAdmin check
            try
            {
                await _productService.DeleteProduct(productId);
                return new NoContentResult();
            }
            catch
            {
                return new StatusCodeResult(500);
            }
        }
    }
}