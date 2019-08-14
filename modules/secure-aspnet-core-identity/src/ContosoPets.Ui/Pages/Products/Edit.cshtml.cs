using ContosoPets.Ui.Models;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Pages.Products
{
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