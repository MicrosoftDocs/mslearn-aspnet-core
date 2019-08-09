using ContosoPets.Ui.Models;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;
//using Microsoft.AspNetCore.Authorization;

namespace ContosoPets.Ui.Pages.Products
{
    // Add [Authorize(Policy = "Admin")] attribute
    public class CreateModel : PageModel
    {
        private readonly ProductService _productService;

        [BindProperty]
        public Product Product { get; set; }

        public CreateModel(ProductService productService)
        {
            _productService = productService;
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            await _productService.CreateProduct(Product);

            return RedirectToPage("Index");
        }
    }
}