using ContosoPets.Ui.Models;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;
// Add using Microsoft.AspNetCore.Authorization;

namespace ContosoPets.Ui.Pages.Products
{
    // Add [Authorize(Policy = "Admin")] attribute
    public class EditModel : PageModel
    {
        private readonly ProductService _productService;

        [BindProperty]
        public Product Product { get; set; }

        public EditModel(ProductService productService)
        {
            _productService = productService;
        }

        public async Task OnGet(int id) =>
            Product = await _productService.GetProductById(id);

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            await _productService.UpdateProduct(Product);

            return RedirectToPage("Index");
        }
    }
}