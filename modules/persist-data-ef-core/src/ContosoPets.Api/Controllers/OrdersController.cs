using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ContosoPets.Domain.DataTransferObjects;
using ContosoPets.Domain.Models;
using ContosoPets.DataAccess.Services;

namespace ContosoPets.Api.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly OrderService _orderService;

        public OrdersController(OrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpGet]
        public async Task<ActionResult<List<CustomerOrder>>> Get() =>
            await _orderService.GetAll();

        [HttpGet("{id}")]
        public async Task<ActionResult<CustomerOrder>> GetById(int id) =>
            await _orderService.GetById(id);

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            bool isDeleted = await _orderService.Delete(id);

            if (!isDeleted)
            {
                return NotFound();
            }

            return NoContent();
        }

        [HttpPost]
        public async Task<ActionResult<CustomerOrder>> Create(Order newOrder)
        {
            var order = await _orderService.Create(newOrder);

            return CreatedAtAction(nameof(GetById), new { id = order.Id }, order);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> SetFulfilled(int id)
        {
            bool isFulfilled = await _orderService.SetFulfilled(id);

            if (!isFulfilled)
            {
                return NotFound();
            }

            return NoContent();
        }
    }
}