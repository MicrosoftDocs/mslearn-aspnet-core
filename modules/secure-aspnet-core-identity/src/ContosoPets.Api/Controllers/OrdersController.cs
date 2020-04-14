using ContosoPets.Api.Data;
using ContosoPets.Api.Models;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Linq;

namespace ContosoPets.Api.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly ContosoPetsContext _context;

        public OrdersController(ContosoPetsContext context)
        {
            _context = context;
        }

        [HttpGet]
        public ActionResult<List<Order>> GetAll() =>
            _context.Orders.ToList();
    }
}
