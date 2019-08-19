using ContosoPets.Ui.Models;
using ContosoPets.Ui.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace ContosoPets.Ui.Pages.Orders
{
    public class IndexModel : PageModel
    {
        private readonly OrderService _orderService;
        public IEnumerable<Order> Orders { get; private set; } = new List<Order>();

        public IndexModel(OrderService orderService)
        {
            _orderService = orderService;
        }

        public async Task OnGet() =>
            Orders = await _orderService.GetOrders();
    }
}